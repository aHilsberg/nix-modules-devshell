---
role:
    - developers
type: overview
topic:
    - devshell
last-substantial-update: null
---

# nix-modules-devshell

Opinionated, modular configuration for development shells.
Allowing adding of packages, scripts, formating, git hooks and repository files in repo.
Reproducible for every developer and CI.

Provides collection of opinionated packages, formating and utilities for language stacks to
unify and simplify development shell configuration of consumer projects.

## Features

- **Reproducible environments**: Same tools and versions for every developer
- **Modular design**: Enable only what you need (language sdks/tooling, formatters, git-hooks, etc.)
- **Unified formatting**: Single `nix fmt` command for all file types via treefmt
- **Nix-managed files**: Declare configuration files in Nix (such as `.gitignore`), generate them automatically
- **direnv integration**: Automatic environment activation when entering project directory

## Quick Start

> See [Installation](./docs/Installation.md) for details, and how to setup automatic entry into a development shell when entering a directory.
>
> See [Quick Start](./docs/Getting_Started.md) for a intro into the capabilities provided by nix-modules-devshell.

### Install

Import `flakeModule`/`flakeModules.default` in the consumer flake and add the `overlays.default` overlay to pkgs.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-modules-devshell.url = "github:your-org/nix-modules-devshell";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.nix-modules-devshell.flakeModule
      ];
      # apply overlay, flake setup specific

      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      # example configuration
      perSystem = {pkgs, ...}: {
        formatting.enable = true;

        devshells.default = {
          packages = [pkgs.hello];
          env = [
            {
              name = "TESTING";
              value = "WORKS";
            }
          ];

          dotnet.enable = true;
          json.enable = true;
          markdown.enable = true;
          yaml.enable = true;
          xml.enable = true;
          nix.enable = true;
        };
      };
    };
}
```

### Enter the Shell

With direnv (recommended):

```bash
cd <project>
direnv allow  # first time only
```

Without direnv:

```bash
nix develop
```

### Formatting

```bash
# Format all files
nix fmt

# Check without modifying (CI)
nix fmt -- --fail-on-change

# Format specific files
nix fmt -- path/to/file.nix
```

### Nix-Managed Files

Regenerate files declared via the `files` configuration:

```bash
nix run .#generate-nix-managed-files
```

**Note:** Nix-managed files are read-only. Manual changes will be overwritten and cause CI (if git hooks are used) to fail.

## Available Language Stack Modules

| Module     | Contents                                                                                      |
| ---------- | --------------------------------------------------------------------------------------------- |
| `dotnet`   | .NET SDK, dependency versioning util, testing tooling, Formatting with JetBrains code cleanup |
| `json`     | JSON/JSONC formatting with Prettier                                                           |
| `markdown` | Markdown formatting with Prettier                                                             |
| `yaml`     | YAML formatting with deno                                                                     |
| `xml`      | XML/RESX formatting with Prettier plugin-xml                                                  |
| `docker`   | Dockerfile formatting with dockerfmt                                                          |
| `nix`      | Nix formatting (nixfmt) and linting (deadnix)                                                 |
| `python`   | Python interpreter environment, Ruff lint fixes and formatting                                |

## References / Projects that have been build upon

- [numtide/devshell](https://github.com/numtide/devshell)
- [flake-parts](https://github.com/hercules-ci/flake-parts)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [mightyiam/files](https://github.com/mightyiam/files)
- [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix)

## License

See [LICENSE](./LICENSE) for details.
