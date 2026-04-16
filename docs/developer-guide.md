# Developer Guide

This guide explains the internal architecture of `nix-modules-devshell` for developers who want to understand, contribute to, or extend the codebase.

> **Note:** This is developer documentation. For usage instructions, see the [README](../README.md) and [Getting Started](./getting-started.md).

## Table of Contents

- [Overview](#overview)
- [Entry Points](#entry-points)
    - [flake.nix](#flake-nix)
    - [flake-module.nix](#flake-module-nix)
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

## <a id="overview"></a>Overview

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

## <a id="entry-points"></a>Entry Points

### <a id="flake-nix"></a>`flake.nix`

The flake exposes the module for consumers:

```nix
flake.flakeModule = config.flakeModules.default;
flake.flakeModules.default = devshellFlakeModule;
```

This flake also **dogfoods** its own module by importing `devshellFlakeModule` directly, allowing us to test the module system on itself.

### <a id="flake-module-nix"></a>`flake-module.nix`

The main entry point that consumers import. It:

1. Imports all modules from `modules/` via `import-tree`
2. Declares the `devshells.<name>` option as a submodule (the submodules beeing imported from `devshell-submodules` via `import-tree`)
3. Passes `specialArgs` to submodules for cross-scope communication
4. Maps `devshells` to `devShells` outputs

```nix
# flake-module.nix (simplified)
{
  imports = [ (import-tree ./modules) ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({config, ...}: {
    options.devshells = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submoduleWith {
          modules = [ (import-tree ./devshell-submodules) ]
                    ++ config.devshell-submodule-extension;
          specialArgs = {
            perSysCfg = config;      # perSystem config passed to submodules
            customPkgs = ...;        # packages from perSystem
          };
        }
      );
    };

    config.devShells = lib.mapAttrs (_: cfg: cfg.build.shell) config.devshells;
  });
}
```

## <a id="module-system"></a>Module System

The configuration has two layers:

### <a id="persystem-modules"></a>1. perSystem Modules (`modules/`)

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

### <a id="devshell-submodules"></a>2. Devshell Submodules (`devshell-submodules/`)

These define **per-devshell options** for language/tool support:

| Submodule             | Purpose                                           |
| --------------------- | ------------------------------------------------- |
| `core.nix`            | Base shell options (`packages`, `env`, `startup`) |
| `dotnet.nix`          | .NET SDK and tooling                              |
| `nix.nix`             | Nix formatting (alejandra, deadnix)               |
| `json.nix`            | JSON formatting                                   |
| `yaml.nix`            | YAML formatting                                   |
| `markdown.nix`        | Markdown formatting                               |
| `xml.nix`             | XML formatting                                    |
| `docker.nix`          | Dockerfile formatting                             |
| `git-hooks.nix`       | Adds git-hooks package to shell                   |
| `file-generation.nix` | Adds file generation package to shell             |

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

## <a id="communication-between-scopes"></a>Communication Between Scopes

The two module layers need to communicate in both directions:

### <a id="submodules-to-persystem"></a>Direction 1: Submodules → perSystem (Aggregation)

Submodules can declare data that gets aggregated at the perSystem level.

**Mechanism:** `devshell-submodule-extension`

A perSystem module can inject options into all devshell submodules:

```nix
# modules/formatting.nix
config.devshell-submodule-extension = [
  ({lib, ...}: {
    options.formatting.treefmt = lib.mkOption {
      # Options that each devshell can set
    };
  })
];
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
2. `devshell-submodules/nix.nix` sets `config.formatting.treefmt.programs.alejandra.enable = true`
3. `modules/formatting.nix` aggregates all `formatting.treefmt` values into the global `treefmt` config

### <a id="persystem-to-submodules"></a>Direction 2: perSystem → Submodules (Dependencies)

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

## <a id="adding-new-features"></a>Adding New Features

### <a id="adding-persystem-option"></a>Adding a perSystem Option

Create a new file in `modules/`:

```nix
# modules/my-feature.nix
{
  flake-parts-lib,
  lib,
  ...
}: {
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

### <a id="adding-devshell-submodule"></a>Adding a Devshell Submodule

Create a new file in `devshell-submodules/`:

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

### <a id="adding-submodule-options-from-persystem"></a>Adding Submodule Options from perSystem

When perSystem needs data from submodules:

```nix
# modules/my-aggregator.nix
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
```

## <a id="key-files-reference"></a>Key Files Reference

| File                           | Purpose                                |
| ------------------------------ | -------------------------------------- |
| `flake.nix`                    | Flake definition, dogfooding, exports  |
| `flake-module.nix`             | Main module entry point for consumers  |
| `lib.nix`                      | Shared utility functions               |
| `pkgs.nix`                     | Package overlays                       |
| `modules/`                     | perSystem-level modules                |
| `devshell-submodules/`         | Per-devshell submodules                |
| `devshell-submodules/core.nix` | Base shell options, builds final shell |
| `packages/`                    | Custom packages exposed by the flake   |
