---
role:
    - developers
    - maintainers
type: how_to
topic:
    - formatting
last-substantial-update: "2026-10-18"
---

## Formatting {#formatting}

### Table of Contents {#table-of-contents}

- [Why treefmt?](#why-treefmt)
- [treefmt-nix Integration](#treefmt-nix-integration)
- [Configured Formatters](#configured-formatters)
- [EditorConfig](#editorconfig)
- [Developer Guide: Defining Formatters](#developer-guide)
    - [Architecture: One Global treefmt, Multiple Shell Contributions](#architecture-one-global-treefmt-multiple-shell-contributions)
    - [Module Structure](#module-structure)
    - [Two Configuration Methods](#two-configuration-methods)
    - [Best Practices](#best-practices)

### Why treefmt? {#why-treefmt}

In a multi-language, multi-file-type repository, consistent formatting requires multiple CLI tools (language-specific formatters or even multiple formatters for the same file type). Managing these individually creates challenges:

1. **Execution order**: Preventing two formatters from running on the same file simultaneously
2. **CI complexity**: Scripts must invoke each formatter separately
3. **Configuration sprawl**: Each tool has its own configuration file format

**treefmt** solves these problems by:

- Acting as a unified wrapper for all formatters
- Managing execution order and parallelization
- Providing a single command to format (`treefmt`) and check (`treefmt --fail-on-change`)
- Supporting Nix integration via `treefmt-nix` for declarative configuration

### treefmt-nix Integration {#treefmt-nix-integration}

Since we use Nix, `treefmt-nix` enables:

- Generation of a wrapped `treefmt` command with baked-in configuration
- Execution of formatters via `nix fmt` or the `treefmt` command in the dev shell
- Formatter configuration in Nix and splitting across multiple files (by language/concern)
- Easy use of widely-used pre-configured formatters [See here](https://github.com/numtide/treefmt-nix#supported-programs)

### Configured Formatters {#configured-formatters}

| Module                          | Formatter                            | EditorConfig handling |
| ------------------------------- | ------------------------------------ | --------------------- |
| [Nix](modules/Nix.md)           | nixfmt or Alejandra; deadnix linting | Build-time mapping    |
| [Python](modules/Python.md)     | Ruff lint fixes and formatting       | Build-time mapping    |
| [.NET](modules/Dotnet.md)       | JetBrains ReSharper `cleanupcode`    | Native, per file      |
| [XML/RESX](modules/Xml.md)      | Prettier with the XML plugin         | Native, per file      |
| [Markdown](modules/Markdown.md) | Prettier                             | Native, per file      |
| [YAML](modules/Yaml.md)         | `deno fmt`                           | Build-time mapping    |
| [JSON/JSONC](modules/Json.md)   | Prettier                             | Native, per file      |
| [Dockerfile](modules/Docker.md) | dockerfmt                            | Native, per file      |

### EditorConfig {#editorconfig}

Every language-stack formatter honors at least part of the project's `.editorconfig`. **Common EditorConfig settings** that are supported by most formatters are:

- `indent_style`
- `indent_size`
- `tab_width`
- `max_line_length`

> 3Support for other standard settings, such as `end_of_line` and `insert_final_newline`, and for
> formatter-specific settings is documented on each module page. "Supports EditorConfig" does not imply support
> for every EditorConfig property.

Formatters with _native support_ resolve EditorConfig against each actual input path when they run. Consequently,
nested `.editorconfig` files and path-specific sections can apply, and editor config edits are visible on the next formatter run.

Some formatters instead translate EditorConfig values into formatter options during Nix evaluation/build - as a workaround for tools without native support: each build queries the root
`.editorconfig` using one representative root-level filename (with the relevant extension, for example `.py` when wanting to get editorconfig values for python formatter). The resulting config values are
shared by all files of that type; it is not resolved separately for each real path. Nested EditorConfig files and
more specific path rules therefore do not apply. After changing `.editorconfig`, reevaluate/rebuild the formatter for it to pick up changes.

### Developer Guide: Defining Formatters {#developer-guide}

Language-specific formatter contributions live in `devshell-submodules/*.lib.nix`. Each library fragment exports a constructor under `projectLib.modules.devshell.<name>`; applying the shell context returns an ordinary NixOS-style module. Every constructor accepts this context stage, even when it does not use it. Both module registries are applied automatically; adding a formatter does not require editing a central module list.

The shared integration lives in `modules/formatting.lib.nix`, which exports **both** `projectLib.modules.flake.formatting` and `projectLib.modules.devshell.formatting`. See the [Developer Guide](contributer-references/Developer_Guide.md#module-pattern) for the library-fragment and context conventions.

#### Architecture: One Global treefmt, Multiple Shell Contributions {#architecture-one-global-treefmt-multiple-shell-contributions}

**Key Concept**: There is **ONE** global `treefmt` configuration for the entire project, assembled from contributions from all devshells.

```nix
treefmt = lib.mkMerge (
    [
        {
            pkgs = pkgs;
            settings.excludes = config.formatting.excludes;
            programs.prettier.package = lib.mkDefault pkgs.prettier;
        }
    ]
    ++ lib.mapAttrsToList
    (_: shellCfg: shellCfg.formatting.treefmt or {})
    config.devshells
);
```

The aggregation above runs in the consumer's `perSystem` scope inside `modules.flake.formatting`, when `formatting.enable` is enabled. That constructor imports `localInputs.treefmt-nix.flakeModule` itself; the root module does not maintain feature-specific dependencies.

**How it works**:

1. **Shell schema**: `modules.devshell.formatting` derives `formatting.treefmt` from `perSysOptions.treefmt.type.getSubOptions []`, where `perSysOptions` is the consumer's `perSystem` option tree. It retains the existing filtered, visible/writable settings and program options, excluding `_module` and `global` from settings. This is a normal shell module declaration, not option injection from `perSystem`.
2. **Shell-specific configuration**: Each devshell (e.g., backend, frontend, docs) can enable formatters based on the languages/tools it needs
3. **Configuration merging**: `modules.flake.formatting` merges all `formatting.treefmt` values from the consumer's `config.devshells` into one global treefmt configuration
4. **Project-wide formatting**: When you run `treefmt` or `nix fmt`, it formats **all files in the project** that match enabled formatters, regardless of which shell enabled them

**Example scenario**:

- `backend` shell enables C# and SQL formatters
- `frontend` shell enables TypeScript and CSS formatters
- `docs` shell enables Markdown formatter
- **Result**: One treefmt command that formats **all** C#, SQL, TypeScript, CSS, and Markdown files across the **entire project**

**Important implications**:

- You cannot scope formatters to specific subdirectories via shell configuration
- If a formatter is enabled in any shell, it will format all matching files project-wide
- Use `excludes` patterns (at global or formatter level) to skip specific paths
- Global excludes are defined in `modules/formatting.lib.nix` and apply to all formatters

```nix
excludes = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
        # Visual Studio Code
        ".vscode/**"
        # JetBrains IDEs
        ".idea/**"
        # Visual Studio
        ".vs/**"
        # direnv
        ".direnv/**"
        # ... more IDE/tool directories
    ];
    description = ''A global list of paths to exclude from all formatters.'';
};
```

#### Module Structure {#module-structure}

A formatter contribution follows this pattern (using Markdown as an example):

```nix
# devshell-submodules/markdown.lib.nix
{...}: {
    modules.devshell.markdown = {...}: {lib, config, ...}: {
        options.markdown.enable = lib.mkEnableOption "Markdown formatting for this shell";

        config = lib.mkIf config.markdown.enable {
            formatting.treefmt.programs.prettier = {
                enable = true;
                includes = ["*.md" "*.markdown"];
            };
        };
    };
}
```

The first function is the library fragment; the function assigned to `modules.devshell.markdown` accepts the shell context; the last function receives the actual shell module arguments. Request `config`, `lib`, `name`, `options`, and `pkgs` from those module arguments, not from the context. Shared `pkgs` and `system` are supplied through the shell's `submoduleWith.specialArgs`.

For provider tools, capture `customPkgs` in the constructor's context stage, for example `modules.devshell.dotnet = {customPkgs, ...}: {lib, config, pkgs, ...}: { ... };`. This package set comes from the provider's `withSystem system ({config, ...}: config.packages)`, populated by its `packages/` and `modules/` modules. It is distinct from the consumer's `pkgs` and `perSysCfg.packages`.

#### Two Configuration Methods {#two-configuration-methods}

**Method 1: Using Built-in treefmt-nix Programs** (Recommended)

For formatters supported by treefmt-nix, use `programs.<formatter>`:

```nix
formatting.treefmt = {
    programs.prettier = {
        enable = true;
        includes = [
            "*.md"
            "*.markdown"
        ];
    };
};
```

**Method 2: Custom Formatter Configuration**

For formatters not built into treefmt-nix, use `settings.formatter`:

```nix
formatting.treefmt = {
    settings.formatter = {
        "jb" = {
            command = lib.getExe customPkgs.jetbrains-globaltools;
            options = [
                "cleanupcode"
            ];
            includes = [
                "*.cs"
                "*.csproj"
                "Directory.Packages.props"
            ];
            excludes = ["legacy/**"];
        };
    };
};
```

#### Best Practices {#best-practices}

- **Use built-in programs when available**: Check [treefmt-nix supported programs](https://github.com/numtide/treefmt-nix#supported-programs) first
- **Respect `.editorconfig`**: Prefer native support; otherwise map supported settings explicitly and document when they are evaluated
- **Use priorities wisely**: Order formatters to avoid conflicts (e.g., remove dead code before formatting)
- **Provide sensible defaults**: Make formatters work out-of-the-box with minimal configuration
- **Document options**: Use clear descriptions for any configurable options
- **Keep modules focused**: One module per language/concern for better maintainability
- **Remember project-wide scope**: Formatters apply to the entire project, not just shell-specific subdirectories
