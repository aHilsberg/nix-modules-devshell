---
role:
    - maintainers
type: overview
topic:
    - module-system
last-substantial-update: "2026-10-19"
---

# Developer Guide {#developer-guide}

This guide explains the internal architecture of `nix-modules-devshell` for developers who want to understand, contribute to, or extend the codebase. File paths are relative to the `nix-modules-devshell` repository.

## Table of Contents {#table-of-contents}

- [Overview](#overview)
- [Repository File Tree](#repository-file-tree)
- [Entry Points](#entry-points)
    - [`flake.nix`](#flake-nix)
    - [`lib.nix`](#lib-nix)
    - [`flake-module.nix`](#flake-module-nix)
- [Module Argument Injection](#module-argument-injection)
    - [The Problem](#the-problem)
    - [The Solution: Registry Constructors](#the-solution-importtreeapply)
    - [Module Pattern](#module-pattern)
    - [Aspect-oriented File Layout](#feature-file-layout)
- [Communication Between Scopes](#communication-between-scopes)
    - [Direction 1: Submodules → perSystem (Aggregation)](#submodules-to-persystem)
    - [Direction 2: perSystem → Submodules (Dependencies)](#persystem-to-submodules)
- [Adding New Features](#adding-new-features)
    - [Adding a perSystem Option](#adding-persystem-option)
    - [Adding a Devshell Submodule](#adding-devshell-submodule)
    - [Adding Paired Flake and Devshell Modules](#adding-submodule-options-from-persystem)

## Overview {#overview}

Consumers import the exported flake-parts module and configure project-wide settings and individual shells:

```nix
{
    imports = [inputs.nix-modules-devshell.flakeModule];

    perSystem = {pkgs, ...}: {
        formatting.enable = true;
        git-hooks.enable = true;

        devshells.default = {
            packages = [pkgs.hello];
            dotnet.enable = true;
            nix.enable = true;
        };
    };
}
```

Internally, composition has three stages:

1. **Build the library**: `projectLib` is constructed following [nix project conventions](./Nix_Project_Conventions.md), which discovers library fragments and merges project wide `*.lib.nix` files that contain module fragements.
2. **Project local information embedded in exported flakeModule**: the flake root passes via `importApply` this project local input and projectLib to the output module.
3. **Evaluate ordinary modules**: the output module is a flake-parts module that imports all flake-parts modules and shell submodules present in the `projectLib`.

> A `*.lib.nix` feature file is therefore a **library fragment**, not a module thats directly imported. Its exports are **context → ordinary module** constructors (either a flake level module, or a devshell level module). Feature fragments live under `modules/` and are grouped by concern: a single file can export both a flake module and a devshell module.

## Repository File Tree {#repository-file-tree}

```text
nix-modules-devshell/
├── flake.nix                       # Provider inputs/outputs, imports, and dogfooding
├── flake-module.nix                # Consumer entry point and module-registry composition
├── lib.nix                         # Library-fragment discovery and merging
├── pkgs.nix                        # Provider's per-system package set and overlays
├── documentation.nix               # Option-reference generation and mdBook build/preview
├── modules/                        # features; flake and shell exports colocated by concern
│   └── language-ecosystems/        # Per-shell language/tool support
├── packages/                       # packaged applications, available through customPkgs
├── docs/                           # mdBook chapters and reference material
│   ├── contributer-references/     # Architecture and contribution guides
│   ├── modules/                    # Ecosystem user guides
│   ├── options/                    # Option reference (generated)
│   └── source/                     # Nix sources for documentation includes (generated)
├── README.md                       # Consumer overview and quick start
├── .editorconfig                   # Editing and formatter policy
├── .data/                          # Local generated output and runtime data (ignored)
└── .direnv/                        # Cached development environment (ignored)
```

## Entry Points {#entry-points}

### `flake.nix` {#flake-nix}

This repository's flake is importing external build upon flakes and exports the flake module for consumers to use.
It also dogfoods the consumer module.

The flake constructs `projectLib`, then binds the exported root module with `importApply`.

```nix
# flake.nix: inside mkFlake; inputs, self, and nixpkgs come from outputs
{config, flake-parts-lib, withSystem, ...}: let
    projectLib = import ./lib.nix {
        inherit inputs self;
        inherit (nixpkgs) lib;
    };
    devshellFlakeModule = flake-parts-lib.importApply ./flake-module.nix {
        localInputs = inputs;
        inherit projectLib withSystem;
    };
in {
    _module.args.projectLib = projectLib;
    imports = [devshellFlakeModule];
    flake.flakeModule = config.flake.flakeModules.default;
    flake.flakeModules.default = devshellFlakeModule;
}
```

`localInputs`, `projectLib`, and `withSystem` are bound to the local flake - their not overwritten/set to be the consumer information. In contrast, `self` is obtained later from the root module's ordinary arguments, so it is the consumer's flake.

> This distinction matters for repository paths such as `self + "/.editorconfig"`.

### `lib.nix` {#lib-nix}

`lib.nix` is a pure library builder, **not a flake-parts module**. It:

- uses `import-tree` to discover `*.lib.nix` fragments recursively from the repository root
- discovers feature fragments under `modules/`, including `modules/language-ecosystems/`, and helpers such as `tests/test.lib.nix` through the same scan;
- uses `lib.fix` to let fragments refer to the completed `projectLib` without constructing the library through module configuration;
- recursively merges attribute-set branches and rejects duplicate leaves instead of silently overwriting an export.

Each discovered fragment must return a function, which the builder calls with `{inputs, lib, self, projectLib}`. A fragment can contribute ordinary helpers as well as module constructors; `tests/test.lib.nix`, for example, contributes the testing library rather than a feature module.

### `flake-module.nix` {#flake-module-nix}

The consumer-facing root module applies uses the modules registed in the `projectLib`.

```nix
# flake-module.nix: simplified composition
{localInputs, projectLib, withSystem}: {lib, flake-parts-lib, self, ...}: let
    applyModules = context: registry:
        map (makeModule: makeModule context) (lib.attrValues registry);

    flakeContext = {inherit localInputs projectLib withSystem;};
in {
    # all `flake` level modules are imported as flake-parts modules
    imports = applyModules flakeContext projectLib.modules.flake;

    options.perSystem = flake-parts-lib.mkPerSystemOption (
        {config, options, pkgs, system, ...}: let
            customPkgs = withSystem system ({config, ...}: config.packages);
            shellContext = flakeContext // {
                inherit self customPkgs;
                perSysCfg = config;
                perSysOptions = options;
            };
        in {
            options.devshells = lib.mkOption {
                type = lib.types.lazyAttrsOf (
                    lib.types.submoduleWith {
                        # all `devshell` level modules are added to the 'per-devshell' module
                        modules = applyModules shellContext projectLib.modules.devshell;
                        specialArgs = {inherit pkgs system;};
                    }
                );
                default = {};
            };

            config.devShells = lib.mapAttrs
                (_: shellCfg: shellCfg.build.shell)
                config.devshells;
        }
    );
}
```

## Module Argument Injection {#module-argument-injection}

### The Problem {#the-problem}

Feature modules sometimes need local flake inputs to determine their `imports`.
Devshell feature modules also need to read `perSystem` settings.

### The Solution: Registry Constructors {#the-solution-importtreeapply}

Constructors capture explicit context before the ordinary module is evaluated:

```nix
applyModules = context: registry:
    map (makeModule: makeModule context) (lib.attrValues registry);
```

The flake level modules receives exactly the generic `flakeContext`: `{localInputs, projectLib, withSystem}`. The devshell level modules receives that context extended with `{self, customPkgs, perSysCfg, perSysOptions}`.
`pkgs` and `system` are shared with devshell modules through `submoduleWith.specialArgs`.

### Module Pattern {#module-pattern}

A library fragment exports named constructors; **every constructor has a context stage**:

```nix
{...}:  # arguments passed by the library constructor
{
    # flake level modules
    modules.flake.example = {localInputs, ...}: # arguments `localInputs, projectLib, withSystem` passed by module constructor
        {...}: # flake-parts module arguments + nix module arguments
        {
            # flake-parts module body
            imports = [localInputs.treefmt-nix.flakeModule];
        };

    # devshell level modules
    modules.devshell.example = {...}: # arguments `self, customPkgs, perSysCfg, perSysOptions` passed by module constructor
        {lib, config, pkgs, ...}: # nix module arguments
        {
            # nix module body
            options.example.enable = lib.mkEnableOption "example tooling";
            config = lib.mkIf config.example.enable {
                packages = [pkgs.hello];
            };
        };
}
```

### Aspect-oriented File Layout {#feature-file-layout}

The annotated [repository file tree](#repository-file-tree) shows where shared features and language-ecosystem fragments live.

Keep both sides of a cross-scope feature in one fragment. For example, `modules/git-hooks.lib.nix` exports `modules.flake.gitHooks` and `modules.devshell.gitHooks`; `modules/file-generation.lib.nix`, `modules/formatting.lib.nix`, and `modules/global-startup.lib.nix` follow the same pattern. `core.lib.nix` exports only the shell foundation, while `gitignore.lib.nix` exports only a flake module.

The location f language-ecosystem fragments is organizational: nested directories are discovered automatically, and a fragment's module level exports still determine its evaluation scope.

## Communication Between Scopes {#communication-between-scopes}

### Direction 1: Submodules → perSystem (Aggregation) {#submodules-to-persystem}

A devshell module declares contribution options normally. A flake module reads their evaluated values from the consumer's `config.devshells` and aggregates them.

> ##### Formatting module that declares `formatting.treefmt` in every shell and consumes its config values to set perSystem level config
>
> 1.  `modules.devshell.formatting`, exported by `modules/formatting.lib.nix`, declares `formatting.treefmt` in every shell.
> 2.  Language modules such as `modules.devshell.nix`, exported by `modules/language-ecosystems/nix.lib.nix`, set those shell-local options.
> 3.  `modules.flake.formatting`, exported by the same fragment, merges the values into the consumer's system-wide treefmt configuration when formatting is enabled.
>
> The flake-side aggregation uses ordinary consumer `perSystem` configuration:
>
> ```nix
> # Inside the formatting flake module's perSystem configuration
> config = lib.mkIf config.formatting.enable {
>    treefmt = lib.mkMerge (
>        [
>            {
>                inherit pkgs;
>                settings.excludes = config.formatting.excludes;
>                programs.prettier.package = lib.mkDefault pkgs.prettier;
>            }
>        ]
>        ++ lib.mapAttrsToList
>            (_: shellCfg: shellCfg.formatting.treefmt or {})
>            config.devshells
>    );
> };
> ```
>
> ```nix
> # Inside modules.devshell.formatting
> {perSysOptions, ...}: {lib, pkgs, ...}: let
>    treefmtOpts = perSysOptions.treefmt.type.getSubOptions [];
>
>    visibleSettingsOptions = ...; # options filtered
>    visibleProgramOptions = ...; # options filtered
> in {
>    options.formatting.treefmt = lib.mkOption {
>        type = lib.types.submodule {
>            options = {
>                settings = lib.mkOption {
>                    type = lib.types.submodule {
>                        freeformType = (pkgs.formats.toml {}).type;
>                        options = visibleSettingsOptions;
>                    };
>                    default = {};
>                };
>                programs = lib.mkOption {
>                    type = lib.types.submodule {options = visibleProgramOptions;};
>                    default = {};
>                };
>            };
>        };
>        default = {};
>    };
> }
> ```

### Direction 2: perSystem → Submodules (Dependencies) {#persystem-to-submodules}

The devshell module constructor context carries cross-scope settings and flake local packages.

| Value                              | Origin and meaning                                                                             |
| ---------------------------------- | ---------------------------------------------------------------------------------------------- |
| `localInputs`                      | Provider inputs, captured by `importApply`                                                     |
| `projectLib`                       | Provider library constructed in the root module's `let`, independently of module configuration |
| `withSystem`                       | Provider's flake-parts helper, captured by `importApply`                                       |
| `self`                             | Consumer flake, received by the ordinary root module                                           |
| `perSysCfg`                        | Consumer's enclosing `perSystem.config`                                                        |
| `perSysOptions`                    | Consumer's enclosing `perSystem.options`                                                       |
| `customPkgs`                       | Provider's system-specific `config.packages`                                                   |
| `pkgs`                             | Consumer's package set, supplied as an ordinary shell argument through `specialArgs`           |
| `config`, `options`, `name`, `lib` | Actual shell module arguments, not context fields                                              |

> ##### git-hooks fragment does devshell module configuration based on `perSystem` config
>
> ```nix
> # modules/git-hooks.lib.nix (shell export)
> {...}: {
>    modules.devshell.gitHooks = {customPkgs, perSysCfg, ...}: {lib, ...}: {
>        commands = lib.mkIf perSysCfg.git-hooks.enable [
>            {
>                name = "run-git-hooks";
>                package = customPkgs.run-git-hooks;
>                category = "development";
>                help = "Run the configured Git hooks.";
>            }
>        ];
>
>        startup.git-hooks = lib.mkIf perSysCfg.git-hooks.enable {
>            text = perSysCfg.pre-commit.installationScript;
>        };
>    };
> }
> ```

## Adding New Features {#adding-new-features}

Add a uniquely named `*.lib.nix` fragment under `modules/`: put shared infrastructure and cross-scope concerns directly in that directory, and language/tool-specific features under `modules/language-ecosystems/`. Extend an existing fragment when the change belongs to the same concern, keeping any flake and shell exports together.

### Adding a perSystem Option {#adding-persystem-option}

For example, a feature exposing an optional package could be:

```nix
# modules/hello.lib.nix
{...}: {
    modules.flake.hello = {...}: {flake-parts-lib, lib, ...}: {
        options.perSystem = flake-parts-lib.mkPerSystemOption (
            {config, pkgs, ...}: {
                options.hello.enable = lib.mkEnableOption "the hello package";
                config = lib.mkIf config.hello.enable {
                    packages.hello = pkgs.hello;
                };
            }
        );
    };
}
```

### Adding a Devshell Submodule {#adding-devshell-submodule}

A shell-only language/tool feature belongs under `modules/language-ecosystems/`. Shared shell infrastructure belongs directly under `modules/`, as `core.lib.nix` does.

```nix
# modules/language-ecosystems/hello.lib.nix
{...}: {
    modules.devshell.hello = {...}: {lib, config, pkgs, ...}: {
        options.hello.enable = lib.mkEnableOption "hello in this shell";
        config = lib.mkIf config.hello.enable {
            packages = [pkgs.hello];
        };
    };
}
```

Consumers can then set `perSystem.devshells.default.hello.enable = true`.

### Adding Paired Flake and Devshell Modules {#adding-submodule-options-from-persystem}

When a feature spans both system configuration and devshell configuration, export both modules from one library fragment.

```nix
# modules/my-aggregator.lib.nix
{...}: {
    modules.flake.myAggregator = {...}: {flake-parts-lib, lib, ...}: {
        options.perSystem = flake-parts-lib.mkPerSystemOption ({config, ...}: {
            options.my-aggregator.allData = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                readOnly = true;
            };

            config.my-aggregator.allData = lib.concatMap
                (shellCfg: shellCfg.my-aggregator.data)
                (lib.attrValues config.devshells);
        });
    };

    modules.devshell.myAggregator = {...}: {lib, ...}: {
        options.my-aggregator.data = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
        };
    };
}
```

If the shell schema depends on upstream `perSystem` options, capture `perSysOptions` in the shell constructor, as formatting does. If the shell needs a project-wide setting, capture `perSysCfg`.
