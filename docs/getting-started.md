# Getting Started

This guide explains how to use the nix-modules-devshell development environment in your projects.

## Table of Contents

- [Entering the Development Shell](#entering-the-development-shell)
    - [With direnv (Recommended)](#with-direnv)
    - [Without direnv](#without-direnv)
- [Formatting Code](#formatting-code)
    - [Format All Files](#format-all-files)
    - [Format Specific Files](#format-specific-files)
    - [Check Formatting Without Modifying (CI)](#check-formatting-ci)
    - [Passing Options to the Formatter](#passing-options-to-formatter)
- [Nix-Managed Files](#nix-managed-files)
    - [How It Works](#nix-managed-how-it-works)
    - [Regenerating Managed Files](#regenerating-managed-files)
    - [CI Check](#nix-managed-ci-check)
- [Available Modules](#available-modules)
    - [Enabling Modules](#enabling-modules)
- [Git Hooks](#git-hooks)
    - [Enabling Git Hooks](#enabling-git-hooks)
    - [Available Hooks](#available-hooks)
    - [Running Hooks Manually](#running-hooks-manually)
    - [Configuring Manual Run Stages](#configuring-manual-run-stages)
    - [Skip Hooks (Emergency Only)](#skip-hooks)
- [Useful Commands](#useful-commands)
- [References](#references)

## <a id="entering-the-development-shell"></a>Entering the Development Shell

### <a id="with-direnv"></a>With direnv (Recommended)

If you have direnv installed and configured:

```bash
cd <project-directory>
direnv allow  # Only required the first time
# The environment activates automatically
```

### <a id="without-direnv"></a>Without direnv

```bash
cd <project-directory>
nix develop
```

This provides all tools, SDKs, and configures environment variables automatically.

## <a id="formatting-code"></a>Formatting Code

The development environment uses **treefmt** (via `nix fmt`) as a unified wrapper for all formatters. This ensures consistent formatting across different file types and languages.

### <a id="format-all-files"></a>Format All Files

```bash
nix fmt
```

### <a id="format-specific-files"></a>Format Specific Files

```bash
nix fmt -- path/to/file.nix path/to/other.md
```

### <a id="check-formatting-ci"></a>Check Formatting Without Modifying (CI)

```bash
nix fmt -- --fail-on-change
# or
nix flake check
```

### <a id="passing-options-to-formatter"></a>Passing Options to the Formatter

Arguments after `--` are forwarded to the underlying formatter:

```bash
nix fmt -- --check .
nix fmt -- --quiet
```

**Note:** The forwarded arguments must be supported by the formatter configured in your flake.

## <a id="nix-managed-files"></a>Nix-Managed Files

Some files in your project may be generated and managed by Nix. These files are **read-only** and should not be edited manually.

### <a id="nix-managed-how-it-works"></a>How It Works

The `files` module (via `mightyiam/files`) allows declaring files that should be generated from Nix expressions. This is useful for:

- `.gitignore` files with consistent entries
- Configuration files that should stay in sync with Nix definitions
- Any file that should be derived from your flake configuration

### <a id="regenerating-managed-files"></a>Regenerating Managed Files

To regenerate all Nix-managed files (this command also runs on devshell setup):

```bash
nix run .#generate-nix-managed-files
```

### <a id="nix-managed-ci-check"></a>CI Check

A check is included that fails if Nix-managed files have been manually modified:

```bash
nix flake check
```

If you see an error about managed files being modified, regenerate them with the command above and commit the changes.

**Important:** Nix-managed files are read-only. Any manual changes will be overwritten when regenerating and will cause CI to fail.

## <a id="available-modules"></a>Available Modules

The devshell supports various language and tool modules that can be enabled:

| Module     | Description                               |
| ---------- | ----------------------------------------- |
| `dotnet`   | .NET SDK and tooling                      |
| `json`     | JSON formatting with Prettier             |
| `markdown` | Markdown formatting with Prettier         |
| `yaml`     | YAML formatting with Prettier             |
| `xml`      | XML formatting with Prettier (plugin-xml) |
| `docker`   | Dockerfile formatting with dockerfmt      |
| `nix`      | Nix formatting with alejandra and deadnix |

### <a id="enabling-modules"></a>Enabling Modules

In your devshell configuration:

```nix
perSystem = {
    devshells.default = {
        dotnet.enable = true;
        json.enable = true;
        markdown.enable = true;
        yaml.enable = true;
        xml.enable = true;
        # ...
    };
};
```

## <a id="git-hooks"></a>Git Hooks

Git hooks are automatically installed when entering the development shell (if `git-hooks.enable = true`). This module uses [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix) under the hood.

### <a id="enabling-git-hooks"></a>Enabling Git Hooks

In your perSystem configuration:

```nix
perSystem = {pkgs, ...}: {
  formatting.enable = true;
  git-hooks.enable = true;

  devshells.default = {
    # ...
  };
};
```

### <a id="available-hooks"></a>Available Hooks

| Hook          | Stage    | Entry / Description    |
| ------------- | -------- | ---------------------- |
| `flake-check` | pre-push | Runs `nix flake check` |

**Note:** Formatting is not checked via git hooks but via `nix flake check` (which runs the treefmt check). This avoids circular dependencies since hooks can run `nix flake check`.

### <a id="running-hooks-manually"></a>Running Hooks Manually

The `run-git-hooks` command is available in the devshell to run all configured hooks manually:

```bash
run-git-hooks
```

By default, this runs hooks for the following stages: `manual`, `pre-commit`, and `pre-push`.

You can also run formatters directly:

```bash
# Format all files (same as what treefmt hook does)
nix fmt

# Check without modifying (as in CI)
nix fmt -- --fail-on-change
```

### <a id="configuring-manual-run-stages"></a>Configuring Manual Run Stages

You can configure which stages `run-git-hooks` executes via `git-hooks.runStages`:

```nix
perSystem = {
  git-hooks = {
    enable = true;
    runStages = ["pre-commit" "pre-push"];  # default: ["manual" "pre-commit" "pre-push"]
  };
};
```

### <a id="skip-hooks"></a>Skip Hooks (Emergency Only)

In rare cases, you can skip hooks:

```bash
git commit --no-verify -m "Commit message"
```

**Note:** Use sparingly. CI will still check formatting.

## <a id="useful-commands"></a>Useful Commands

| Command                                | Description                        |
| -------------------------------------- | ---------------------------------- |
| `nix develop`                          | Enter the development shell        |
| `nix fmt`                              | Format all files                   |
| `nix fmt -- --fail-on-change`          | Check formatting without modifying |
| `nix flake check`                      | Run all checks (formatting, tests) |
| `nix run .#generate-nix-managed-files` | Regenerate Nix-managed files       |
| `direnv allow`                         | Allow direnv for current directory |
| `direnv reload`                        | Reload the development environment |

## <a id="references"></a>References

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [numtide/devshell](https://github.com/numtide/devshell)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix)
- [direnv Documentation](https://direnv.net/)
- [mightyiam/files](https://github.com/mightyiam/files)
