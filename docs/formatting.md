## 🎨 Formatting <a id="formatting"></a>

### Table of Contents

- [Why treefmt?](#why-treefmt)
- [treefmt-nix Integration](#treefmt-nix-integration)
- [Configured Formatters](#configured-formatters)
- [Developer Guide: Defining Formatters](#developer-guide)
    - [Architecture: One Global treefmt, Multiple Shell Contributions](#architecture-one-global-treefmt-multiple-shell-contributions)
    - [Module Structure](#module-structure)
    - [Two Configuration Methods](#two-configuration-methods)
    - [Best Practices](#best-practices)

### Why treefmt? <a id="why-treefmt"></a>

In a multi-language, multi-file-type repository, consistent formatting requires multiple CLI tools (language-specific formatters or even multiple formatters for the same file type). Managing these individually creates challenges:

1. **Execution order**: Preventing two formatters from running on the same file simultaneously
2. **CI complexity**: Scripts must invoke each formatter separately
3. **Configuration sprawl**: Each tool has its own configuration file format

**treefmt** solves these problems by:

- Acting as a unified wrapper for all formatters
- Managing execution order and parallelization
- Providing a single command to format (`treefmt`) and check (`treefmt --fail-on-change`)
- Supporting Nix integration via `treefmt-nix` for declarative configuration

### treefmt-nix Integration <a id="treefmt-nix-integration"></a>

Since we use Nix, `treefmt-nix` enables:

- Generation of a wrapped `treefmt` command with baked-in configuration
- Execution of formatters via `nix fmt` or the `treefmt` command in the dev shell
- Formatter configuration in Nix and splitting across multiple files (by language/concern)
- Easy use of widely-used pre-configured formatters [See here](https://github.com/numtide/treefmt-nix#supported-programs)

### Configured Formatters <a id="configured-formatters"></a>

| Language/Format | Formatter             | Configuration File                 |
| --------------- | --------------------- | ---------------------------------- |
| **Nix**         | alejandra             | `devshell-submodules/nix.nix`      |
| **Nix**         | deadnix (dead code)   | `devshell-submodules/nix.nix`      |
| **C#**          | JetBrains cleanupcode | `devshell-submodules/dotnet.nix`   |
| **XML/RESX**    | prettier (plugin-xml) | `devshell-submodules/xml.nix`      |
| **Markdown**    | prettier              | `devshell-submodules/markdown.nix` |
| **YAML**        | prettier              | `devshell-submodules/yaml.nix`     |
| **JSON**        | prettier              | `devshell-submodules/json.nix`     |
| **Dockerfile**  | dockerfmt             | `devshell-submodules/docker.nix`   |

### Developer Guide: Defining Formatters <a id="developer-guide"></a>

Formatters are defined in the `devshell-submodules/` directory using the NixOS module system. Each language/format has its own module that encapsulates formatter configuration.

#### Architecture: One Global treefmt, Multiple Shell Contributions <a id="architecture-one-global-treefmt-multiple-shell-contributions"></a>

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

**How it works**:

1. **Shell-specific configuration**: Each devshell (e.g., backend, frontend, docs) can enable formatters based on the languages/tools it needs
2. **Configuration merging**: All `formatting.treefmt` configurations from all shells are merged into one global treefmt configuration
3. **Project-wide formatting**: When you run `treefmt` or `nix fmt`, it formats **all files in the project** that match enabled formatters, regardless of which shell enabled them

**Example scenario**:

- `backend` shell enables C# and SQL formatters
- `frontend` shell enables TypeScript and CSS formatters
- `docs` shell enables Markdown formatter
- **Result**: One treefmt command that formats **all** C#, SQL, TypeScript, CSS, and Markdown files across the **entire project**

**Important implications**:

- You cannot scope formatters to specific subdirectories via shell configuration
- If a formatter is enabled in any shell, it will format all matching files project-wide
- Use `excludes` patterns (at global or formatter level) to skip specific paths
- Global excludes are defined in `modules/formatting.nix` and apply to all formatters

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

#### Module Structure <a id="module-structure"></a>

Module that enable/include formatter config follows this pattern:

```nix
{
    lib,
    config,
    pkgs,
    ...
}: {
    options.<language>.enable = lib.mkEnableOption "<description> for this shell";

    config = lib.mkIf config.<language>.enable {
        # Package dependencies
        packages = [ /* formatter packages */ ];

        # Formatter configuration
        formatting.treefmt = {
            # treefmt-nix configuration here
        };
    };
}
```

#### Two Configuration Methods <a id="two-configuration-methods"></a>

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

#### Best Practices <a id="best-practices"></a>

- **Use built-in programs when available**: Check [treefmt-nix supported programs](https://github.com/numtide/treefmt-nix#supported-programs) first
- **Respect `.editorconfig`**: Set `editorconfig = true` when the formatter supports it
- **Use priorities wisely**: Order formatters to avoid conflicts (e.g., remove dead code before formatting)
- **Provide sensible defaults**: Make formatters work out-of-the-box with minimal configuration
- **Document options**: Use clear descriptions for any configurable options
- **Keep modules focused**: One module per language/concern for better maintainability
- **Remember project-wide scope**: Formatters apply to the entire project, not just shell-specific subdirectories
