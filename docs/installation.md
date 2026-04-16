# Installation

This guide covers the installation of Nix and optional tools to use the nix-modules-devshell development environment.

## Table of Contents

- [Adding to Your Project](#adding-to-your-project)
    - [Importing the Flake Module](#importing-the-flake-module)
    - [Consuming the Devshell Overlay](#consuming-the-devshell-overlay)
- [Prerequisites](#prerequisites)
    - [Installing Nix](#installing-nix)
    - [Installing direnv (Optional but Recommended)](#installing-direnv)
- [Verifying Installation](#verifying-installation)
- [Next Steps](#next-steps)

## <a id="adding-to-your-project"></a>Adding to Your Project

### <a id="importing-the-flake-module"></a>Importing the Flake Module

This project provides a [flake-parts](https://flake.parts) module that you must import into your flake configuration.

Add the input and import the module:

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

      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      perSystem = {pkgs, ...}: {
        # Enable formatting and other features
        formatting.enable = true;
        gitignore.enable = true;
        git-hooks.enable = true;

        devshells.default = {
          # Your devshell configuration here
          nix.enable = true;
          json.enable = true;
        };
      };
    };
}
```

### <a id="consuming-the-devshell-overlay"></a>Consuming the Devshell Overlay

When using this flake module, you **must** consume the devshell overlay that is exposed by this flake. The overlay is required for the devshell functionality to work properly.

**Important:** The overlay must be applied to your `pkgs` instance.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-modules-devshell.url = "github:your-org/nix-modules-devshell";
  };

  outputs = inputs @ {flake-parts, nix-modules-devshell, nixpkgs, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({config, ...}: {
      imports = [
        inputs.nix-modules-devshell.flakeModule
      ];

      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      # Re-export the overlay so your consumers can use it
      flake.overlays.default = nix-modules-devshell.overlays.default;

      # Apply the overlay when creating your pkgs
      perSystem = {system, ...}: {
        _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [inputs.nix-modules-devshell.overlays.default];
        };

        formatting.enable = true;
        devshells.default = {
          # Your configuration
        };
      };
    });
}
```

## <a id="prerequisites"></a>Prerequisites

### <a id="installing-nix"></a>Installing Nix

To use this development environment, you need Nix with Flakes enabled.

#### Recommended: Determinate Systems Installer

The [Determinate Systems Nix Installer](https://github.com/DeterminateSystems/nix-installer) provides the simplest installation experience with Flakes enabled by default:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

#### Alternative: Official Nix Installer

Follow the [official Nix installation guide](https://nixos.org/download.html) for your platform, then enable Flakes by adding the following to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### <a id="installing-direnv"></a>Installing direnv (Optional but Recommended)

**direnv** automatically activates the Nix development environment when you enter the project directory. Without direnv, you must manually run `nix develop` each time you open a new terminal.

#### Installation

```bash
# macOS (Homebrew)
brew install direnv

# Linux (Debian/Ubuntu)
sudo apt install direnv

# Linux (Arch)
sudo pacman -S direnv

# Via Nix (if Nix is already installed)
nix profile install nixpkgs#direnv
```

#### Shell Integration

Add the appropriate hook to your shell configuration file:

```bash
# Bash (~/.bashrc)
eval "$(direnv hook bash)"

# Zsh (~/.zshrc)
eval "$(direnv hook zsh)"

# Fish (~/.config/fish/config.fish)
direnv hook fish | source
```

After adding the hook, restart your terminal or reload your shell configuration.

#### First-time Setup

When entering a project directory with an `.envrc` file for the first time:

1. direnv will detect the `.envrc` and ask for permission
2. Grant permission with: `direnv allow`
3. The development environment will automatically activate

The environment activates when entering the directory and deactivates when leaving.

**Tip:** Use `direnv reload` to manually reload the environment if automatic detection doesn't pick up changes.

For more information, see the [direnv documentation](https://direnv.net/).

#### Creating the .envrc File

Projects using this devshell module can use a `.envrc` file in their repository root. Create the file with the following content:

```bash
#!/usr/bin/env bash
# see https://github.com/direnv/direnv/wiki/Nix for available options to load nix devshell

# https://github.com/nix-community/nix-direnv
if ! has nix_direnv_version || ! nix_direnv_version 3.1.1; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.1.1/direnvrc" "sha256-p+fzQdrms/hDa7g+soShAybJNo4bN4SIAeSfqNKgD5I="
fi

export DIRENV_IN_ENVRC=1

watch_file flake.nix
watch_file flake.lock

if ! use flake . --no-pure-eval; then
  echo "devshell could not be built. The devshell environment was not loaded. Make the necessary changes and hit enter to try again." >&2
fi
```

**Key features of this configuration:**

- **nix-direnv integration**: Provides faster reloads and better caching than plain `use flake`
- **DIRENV_IN_ENVRC=1**: Tells devshell it's being loaded via direnv (enables special handling)
- **watch_file**: Automatically reloads when `flake.nix` or `flake.lock` change
- **--no-pure-eval**: Required for proper flake evaluation with direnv

You can also add `watch_dir` directives for directories that should trigger a reload when changed:

```bash
watch_dir nix
watch_dir modules
```

## <a id="verifying-installation"></a>Verifying Installation

After installation, verify everything works:

```bash
# Check Nix installation
nix --version

# Check Flakes support
nix flake --help

# Check direnv (if installed)
direnv --version
```

## <a id="next-steps"></a>Next Steps

See the [Getting Started](./getting-started.md) guide to learn how to use the development environment.
