---
role:
  - maintainers
type: overview
topic:
  - module-system
last-substantial-update: "2026-10-15"
---

# Developer Guide {#developer-guide}

This guide explains the internal architecture of `nix-modules-devshell` for developers who want to understand, contribute to, or extend the codebase.

## Table of Contents {#table-of-contents}

- [Overview](#overview)
- [Entry Points](#entry-points)
    - [flake.nix](#flake-nix)
    - [flake-module.nix](#flake-module-nix)
- [Module Argument Injection](#module-argument-injection)
    - [The Problem](#the-problem)
    - [The Solution: importTreeApply](#the-solution-importtreeapply)
    - [Module Pattern](#module-pattern)
- [Module System](#module-system)
    - [perSystem Modules](#persystem-modules)
    - [Devshell Submodules](#devshell-submodules)
- [Communication Between Scopes](#communication-between-scopes)
    - [Submodules → perSystem (Aggregation)](#submodules-to-persystem)
    - [perSystem → Submodules (Dependencies)](#persystem-to-submodules)
- [Adding New Features](#adding-new-features)
    - [Adding a perSystem Option](#adding-persystem-option)
    - [Adding a Devshell Submodule](#adding-devshell-submodule)
    - [Adding Submodule Options from perSystem](#adding-submodule-options-from-persystem)
- [Key Files Reference](#key-files-reference)

## Overview {#overview}

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Consumer Flake                                 │
│                                                                             │
│   imports = [ inputs.nix-modules-devshell.flakeModule ]                     │
│                                                                             │
│   perSystem = {                ←── perSystem options (modules/)             │
│     formatting.enable = true;                                               │
│     git-hooks.enable = true;                                                │
│                                                                             │
│     devshells.default = {      ←── devshell options (devshell-submodules/)  │
│       dotnet.enable = true;                                                 │
│       nix.enable = true;                                                    │
│     };                                                                      │
│   }                                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Entry Points {#entry-points}

### `flake.nix` {#flake-nix}

The flake exposes the module for consumers using `importApply` to inject local flake arguments:

```nix
# flake.nix (simplified)
outputs = inputs @ {...}:
  flake-parts.lib.mkFlake {inherit inputs;} ({flake-parts-lib, ...}: let
    inherit (flake-parts-lib) importApply;
    devshellFlakeModule = importApply ./flake-module.nix {
      localInputs = inputs;
      inherit projectLib withSystem;
    };
    projectLib = import ./lib.nix {inherit (nixpkgs) lib;};
  in {
    flake.flakeModule = config.flake.flakeModules.default;
    flake.flakeModules.default = devshellFlakeModule;
  });
```

This flake also **dogfoods** its own module by importing `devshellFlakeModule` directly, allowing us to test the module system on itself.

### `flake-module.nix` {#flake-module-nix}

The main entry point that consumers import. It:

1. Receives `localInputs` and `projectLib` via the curried function pattern
2. Imports all modules from `modules/` via `import-tree` with argument injection
3. Declares the `devshells.<name>` option as a submodule
4. Passes `specialArgs` to submodules for cross-scope communication
5. Maps `devshells` to `devShells` outputs

```nix
# flake-module.nix (simplified)
{
  localInputs,
  projectLib,
  withSystem,
}: {
  lib,
  flake-parts-lib,
  ...
}: {
  imports = [
    (localInputs.import-tree.map
      (modulePath: (import modulePath) {inherit localInputs projectLib;})
      ./modules)
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({config, ...}: {
    options.devshells = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submoduleWith {
          modules = [ (localInputs.import-tree ./devshell-submodules) ]
                    ++ config.devshell-submodule-extension;
          specialArgs = {
            perSysCfg = config;
            customPkgs = ...;
          };
        }
      );
    };

    config.devShells = lib.mapAttrs (_: cfg: cfg.build.shell) config.devshells;
  });
}
```

## Module Argument Injection {#module-argument-injection}

### The Problem {#the-problem}

Modules in `modules/` need access to flake-level values like `localInputs` (to import other flake modules) and `projectLib` (for shared utilities). However, we can't use `_module.args` for this because:

1. `_module.args` requires evaluating `config`
2. `imports` are evaluated before `config` is available
3. This creates an infinite recursion when modules try to use `localInputs` in their `imports`

```nix
# ❌ This causes infinite recursion:
{
  _module.args.localInputs = inputs;  # Sets localInputs in config
  imports = [ (import-tree ./modules) ];  # Modules need localInputs for imports
}

# Module tries to use localInputs:
{localInputs, ...}: {
  imports = [ localInputs.treefmt-nix.flakeModule ];  # 💥 Needs config before config exists
}
```

### The Solution: importTreeApply {#the-solution-importtreeapply}

We use `import-tree`'s `.map` function combined with a curried function pattern to inject arguments at import time, before the module system evaluates:

```nix
# flake-module.nix
imports = [
  (localInputs.import-tree.map
    (modulePath: (import modulePath) {inherit localInputs projectLib;})
    ./modules)
];
```

This:

1. Uses `import-tree` to discover all `.nix` files in `./modules`
2. Maps over each discovered path
3. Imports each file and immediately calls it with `{localInputs, projectLib}`
4. The result is a standard flake-parts module that can be evaluated normally

### Module Pattern {#module-pattern}

All modules in `modules/` must use the **nested function pattern**:

```nix
# Outer function: receives injected arguments (localInputs, projectLib)
# Use `...` to accept any arguments - only name the ones you need
{localInputs, ...}:

# Inner function: standard flake-parts module arguments
{lib, flake-parts-lib, ...}:

# Module body
{
  imports = [
    localInputs.treefmt-nix.flakeModule  # ✅ Can use localInputs here
  ];

  options.perSystem = ...;
}
```

**Examples by usage:**

```nix
# Module needs localInputs only:
{localInputs, ...}: {lib, ...}: {
  imports = [ localInputs.git-hooks-nix.flakeModule ];
}

# Module needs projectLib only:
{projectLib, ...}: {lib, ...}: {
  config = projectLib.mkDevShellDefault true;
}

# Module needs both:
{localInputs, projectLib, ...}: {lib, ...}: {
  imports = [ localInputs.treefmt-nix.flakeModule ];
  config = projectLib.mkDevShellDefault true;
}

# Module needs neither (still must accept args):
{...}: {lib, ...}: {
  options.perSystem = ...;
}
```

## Module System {#module-system}

The configuration has two layers:

### 1. perSystem Modules (`modules/`) {#persystem-modules}

These define **flake-wide options** that apply across all devshells:

| Module                | Purpose                                      |
| --------------------- | -------------------------------------------- |
| `formatting.nix`      | treefmt configuration, `nix fmt` integration |
| `git-hooks.nix`       | pre-commit hooks, `run-git-hooks` command    |
| `gitignore.nix`       | Generated `.gitignore` file                  |
| `file-generation.nix` | Nix-managed file generation                  |

**Options declared here are accessed as:**

```nix
perSystem = {
  formatting.enable = true;
  git-hooks.enable = true;
};
```

### 2. Devshell Submodules (`devshell-submodules/`) {#devshell-submodules}

These define **per-devshell options** for language/tool support:

| Submodule             | Purpose                                             |
| --------------------- | --------------------------------------------------- |
| `core.nix`            | Base shell options (`packages`, `env`, `startup`)   |
| `dotnet.nix`          | .NET SDK and tooling                                |
| `nix.nix`             | Nix formatting (nixfmt, deadnix)               |
| `python.nix`          | Python (`withPackages`), Ruff lint fixes/formatting |
| `json.nix`            | JSON formatting                                     |
| `yaml.nix`            | YAML formatting                                     |
| `markdown.nix`        | Markdown formatting                                 |
| `xml.nix`             | XML formatting                                      |
| `docker.nix`          | Dockerfile formatting                               |
| `git-hooks.nix`       | Adds git-hooks package to shell                     |
| `file-generation.nix` | Adds file generation package to shell               |

**Options declared here are accessed as:**

```nix
perSystem = {
    devshells.default = {
        packages = [ pkgs.hello ];
        dotnet.enable = true;
        nix.enable = true;
    };
};
```

> **Note:** Devshell submodules use standard module syntax (not nested functions) because they receive arguments via `specialArgs` instead of import-time injection.

## Communication Between Scopes {#communication-between-scopes}

The two module layers need to communicate in both directions:

### Direction 1: Submodules → perSystem (Aggregation) {#submodules-to-persystem}

Submodules can declare data that gets aggregated at the perSystem level.

**Mechanism:** `devshell-submodule-extension`

A perSystem module can inject options into all devshell submodules:

```nix
# modules/formatting.nix
{localInputs, projectLib, ...}: {lib, ...}: {
  imports = [ localInputs.treefmt-nix.flakeModule ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({config, ...}: {
    config.devshell-submodule-extension = [
      ({lib, ...}: {
        options.formatting.treefmt = lib.mkOption {
          # Options that each devshell can set
        };
      })
    ];
  });
}
```

Then it aggregates values from all devshells:

```nix
# modules/formatting.nix
config.treefmt = lib.mkMerge (
  lib.mapAttrsToList
    (_: shellCfg: shellCfg.formatting.treefmt or {})
    config.devshells
);
```

**Example flow:**

1. `modules/formatting.nix` injects `formatting.treefmt` option into submodules
2. `devshell-submodules/nix.nix` sets `config.formatting.treefmt.programs.nixfmt.enable = true`
3. `modules/formatting.nix` aggregates all `formatting.treefmt` values into the global `treefmt` config

### Direction 2: perSystem → Submodules (Dependencies) {#persystem-to-submodules}

Submodules can access perSystem config and packages via `specialArgs`.

**Mechanism:** `perSysCfg` and `customPkgs`

```nix
# flake-module.nix
specialArgs = {
  perSysCfg = config;           # Full perSystem config
  customPkgs = withSystem system (
    {config, ...}: config.packages
  );
};
```

**Example:**

```nix
# devshell-submodules/git-hooks.nix
{
  customPkgs,
  perSysCfg,
  ...
}: {
  packages = lib.mkIf perSysCfg.git-hooks.enable [
    customPkgs.run-git-hooks           # Package from perSystem
  ];

  startup.git-hooks = lib.mkIf perSysCfg.git-hooks.enable {
    text = perSysCfg.pre-commit.installationScript;  # Config from perSystem
  };
}
```

## Adding New Features {#adding-new-features}

### Adding a perSystem Option {#adding-persystem-option}

Create a new file in `modules/` using the nested function pattern:

```nix
# modules/my-feature.nix

# Outer function: accept injected args (use only what you need)
{localInputs, ...}:

# Inner function: standard flake-parts module
{
  flake-parts-lib,
  lib,
  ...
}: {
  # Optional: import flake modules
  imports = [
    # localInputs.some-flake.flakeModule
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    config,
    pkgs,
    ...
  }: {
    options.my-feature = {
      enable = lib.mkEnableOption "my feature";
      # ... more options
    };

    config = lib.mkIf config.my-feature.enable {
      # ... implementation
    };
  });
}
```

### Adding a Devshell Submodule {#adding-devshell-submodule}

Create a new file in `devshell-submodules/` (standard module syntax, no nesting needed):

```nix
# devshell-submodules/my-tool.nix
{
  lib,
  config,
  pkgs,
  perSysCfg,    # Access perSystem config
  customPkgs,   # Access perSystem packages
  ...
}: {
  options.my-tool = {
    enable = lib.mkEnableOption "my tool support";
  };

  config = lib.mkIf config.my-tool.enable {
    packages = [ pkgs.my-tool ];

    # If using treefmt integration:
    formatting.treefmt.programs.my-formatter.enable = true;
  };
}
```

### Adding Submodule Options from perSystem {#adding-submodule-options-from-persystem}

When perSystem needs data from submodules:

```nix
# modules/my-aggregator.nix
{...}: {flake-parts-lib, lib, ...}: {
  options.perSystem = flake-parts-lib.mkPerSystemOption ({config, ...}: {
    config = {
      # 1. Inject options into submodules
      devshell-submodule-extension = [
        ({lib, ...}: {
          options.my-aggregator.data = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        })
      ];

      # 2. Aggregate from all devshells
      my-aggregator.allData = lib.flatten (
        lib.mapAttrsToList
          (_: shellCfg: shellCfg.my-aggregator.data)
          config.devshells
      );
    };
  });
}
```

## Key Files Reference {#key-files-reference}

| File                           | Purpose                                    |
| ------------------------------ | ------------------------------------------ |
| `flake.nix`                    | Flake definition, dogfooding, exports      |
| `flake-module.nix`             | Main module entry point for consumers      |
| `lib.nix`                      | Shared utility functions                   |
| `pkgs.nix`                     | Package overlays                           |
| `modules/`                     | perSystem-level modules (nested functions) |
| `devshell-submodules/`         | Per-devshell submodules (standard modules) |
| `devshell-submodules/core.nix` | Base shell options, builds final shell     |
| `packages/`                    | Custom packages exposed by the flake       |
