# nix-modules-devshell

Opinionated, modular development shell configuration built on:

- [numtide/devshell](https://github.com/numtide/devshell)
- [flake-parts](https://github.com/hercules-ci/flake-parts)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [mightyiam/files](https://github.com/mightyiam/files)
- [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix)

## Features

- **Reproducible environments**: Same tools and versions for every developer
- **Modular design**: Enable only what you need (language sdks/tooling, formatters, git-hooks, etc.)
- **Unified formatting**: Single `nix fmt` command for all file types via treefmt
- **Nix-managed files**: Declare configuration files in Nix (such as `.gitignore`), generate them automatically
- **direnv integration**: Automatic environment activation when entering project directory

## Quick Start

Import `inputs.nix-modules-devshell.flakeModule` in your flake-parts configuration
and add the `inputs.devshell.overlays.default` overlay to pkgs.

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

## Available Modules

| Module     | Description                                                       |
| ---------- | ----------------------------------------------------------------- |
| `dotnet`   | .NET SDK, testing tooling, Formatting with JetBrains code cleanup |
| `json`     | JSON/JSONC formatting with Prettier                               |
| `markdown` | Markdown formatting with Prettier                                 |
| `yaml`     | YAML formatting with Prettier                                     |
| `xml`      | XML/RESX formatting with Prettier plugin-xml                      |
| `docker`   | Dockerfile formatting with dockerfmt                              |
| `nix`      | Nix formatting (alejandra) and linting (deadnix)                  |

## Documentation

- [Installation](./docs/installation.md) - Installing Nix and direnv
- [Getting Started](./docs/getting-started.md) - Using the development environment
- [Developer Guide](./docs/developer-guide.md) - Internal architecture and module system (for contributors)

### Private documentation website

From this repository's directory:

```sh
# nix build path:.#docsMdBook
nix run path:.#documentation
```

Open <http://127.0.0.1:8000> for the guides and generated option reference.
Stop the preview with Ctrl-C. The preview binds only to loopback; nothing is
published or deployed. You can also open `result/index.html` directly after
building, without starting a server.

`documentation.nix` evaluates this module with `flake-parts.lib.evalFlakeModule`
and stores the result of `pkgs.nixosOptionsDoc` in the local `optionsDoc` variable.
Its CommonMark output supplies the option reference rendered by mdBook; no external
`flake.parts-website` renderer dependency is used. The evaluation guards and source
filtering are adapted from [the upstream renderer](https://github.com/hercules-ci/flake.parts-website/blob/71970b431ae9cce1ae96db17d26583327bd2be2b/render/render-module.nix).

Raw reference output is available with
`nix build path:.#generated-docs-nix-modules-devshell` (in `result/options.md`).
For the JSON output of the same `nixosOptionsDoc` invocation:

```sh
nix build path:.#docsJson --out-link result-json
```

The JSON file is `result-json/share/doc/nixos/options.json` (a Brotli-compressed
copy is also included). Both outputs use the same option filtering and metadata.
Dependencies may be downloaded during the build, but documentation is not uploaded.
Build results live in the Nix store and are readable by other local users; this is
not a secret-storage mechanism. Source declarations are bundled for offline links.

## Usage

### Entering the Shell

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

Regenerate files declared via the `files` module:

```bash
nix run .#generate-nix-managed-files
```

**Note:** Nix-managed files are read-only. Manual changes will be overwritten and cause CI to fail.

## License

See [LICENSE](./LICENSE) for details.
