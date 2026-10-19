---
role:
    - developers
topic:
    - devshell
    - formatting
type: quick_start
last-substantial-update: "2026-10-18"
---

# Getting Started {#getting-started}

This guide explains how to use the nix-modules-devshell development environment in your projects.

## Table of Contents {#table-of-contents}

- [Entering the Development Shell](#entering-the-development-shell)
    - [With direnv (Recommended)](#with-direnv)
    - [Without direnv](#without-direnv)
- [Formatting Code](#formatting-code)
    - [Format All Files](#format-all-files)
    - [Format Specific Files](#format-specific-files)
- [Nix-Managed Files](#nix-managed-files)
- [Available Language Modules](#available-modules)
    - [Enabling Modules](#enabling-modules)
- [Git Hooks](#git-hooks)
    - [Enabling Git Hooks](#enabling-git-hooks)
    - [Available Hooks](#available-hooks)
    - [Registering Hooks](#registering-hooks)
    - [Hook Stages and Automatic Execution](#hook-stages)
    - [Running Hooks Manually](#running-hooks-manually)
    - [Running Only One Stage or Hook](#running-one-stage-or-hook)
    - [Configuring Manual Run Stages](#configuring-manual-run-stages)
    - [Skip Hooks](#skip-hooks)
- [References](#references)

## Entering the Development Shell {#entering-the-development-shell}

### With direnv (Recommended) {#with-direnv}

If you have direnv installed and configured:

```bash
cd <project-directory>
direnv allow  # Only required the first time
# The environment activates automatically
direnv reload # to reload the environment by hand, in case its configuratio was changed
```

### Without direnv {#without-direnv}

```bash
cd <project-directory>
nix develop
```

## Formatting Code {#formatting-code}

The development environment uses **treefmt** (via `nix fmt`) as a unified wrapper for all formatters.

This gives a unified interface to register filetype specific formaters and run them.

### Format All Files {#format-all-files}

```bash
nix fmt
```

### Format Specific Files {#format-specific-files}

```bash
nix fmt -- path/to/file.nix path/to/other.md
```

### Check Formatting Without Modifying (CI) {#check-formatting-ci}

```bash
nix fmt -- --fail-on-change
# or
nix flake check # when the formating check has been enabled
```

### Passing Options to the Formatter {#passing-options-to-formatter}

Arguments after `--` are forwarded to the underlying formatter:

```bash
nix fmt -- --check .
nix fmt -- --quiet
```

> [!note] The forwarded arguments must be supported by the formatter configured in your flake.

## Nix-Managed Files {#nix-managed-files}

Some files in your project may be derived or should be effected by Nix configuration.
This is useful for:

- `.gitignore` (enabling a language stack in the devshell nix config could also add common build result patterns of that language stack to the gitignore)
- Configuration files that should stay in sync with Nix definitions
- Any file that should be derived from your flake configuration

> [!note]
> **Important:** Nix-managed files are read-only. Any manual changes will be overwritten when regenerating and will cause CI to fail.

### Specifing nix managed files {#specifying-nix-managed-files}

The `files` module (this uses [mightyiam/files](https://github.com/mightyiam/files) under the hood) allows declaring files that should be generated from Nix expressions:

```nix
perSystem.files.file = {
  "README.md".text = "# My Project";
  ".gitignore".source = ./gitignore;
  "docs/guide.md".text = "...";
}
```

### Regenerating Managed Files {#regenerating-managed-files}

To regenerate all Nix-managed files (this command also runs on devshell setup):

```bash
nix run .#generate-nix-managed-files
```

### CI Check {#nix-managed-ci-check}

A check is included that fails if Nix-managed files have been manually modified:

```bash
nix flake check
```

If you see an error about managed files being modified, regenerate them with the command above and commit the changes.

## Available Language Modules {#available-modules}

The devshell supports various language and tool modules that can be enabled:

| Module                          | Description                               |
| ------------------------------- | ----------------------------------------- |
| [`dotnet`](./modules/Dotnet.md) | .NET SDK and tooling                      |
| `json`                          | JSON formatting with Prettier             |
| `markdown`                      | Markdown formatting with Prettier         |
| `yaml`                          | YAML formatting with Prettier             |
| `xml`                           | XML formatting with Prettier (plugin-xml) |
| `docker`                        | Dockerfile formatting with dockerfmt      |
| `nix`                           | Nix formatting with nixfmt and deadnix    |

### Enabling Modules {#enabling-modules}

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

## Git Hooks {#git-hooks}

Git hooks use [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix) and its configured hook runner (`pre-commit` by default). Hook definitions live in Nix, not in a handwritten `.pre-commit-config.yaml`.

### Enabling Git Hooks {#enabling-git-hooks}

In your `perSystem` configuration:

```nix
perSystem = {config, ...}: {
  git-hooks.enable = true;
};
```

With `git-hooks.enable = true`, entering the devshell runs the upstream installation script and adds `run-git-hooks` to the shell. The installation script links the generated configuration at the repository root as `.pre-commit-config.yaml` and installs the Git hooks needed by the enabled hook definitions. Do not edit that generated file. If a handwritten configuration already exists there, the installer refuses to overwrite it; migrate its hooks to Nix first.

### Available Hooks {#available-hooks}

| Hook          | Stage      | Description                                     |
| ------------- | ---------- | ----------------------------------------------- |
| `flake-check` | `pre-push` | Enabled by this module; runs `nix flake check`. |

Formatting is checked indirectly by `flake-check` when the treefmt flake check is enabled. There is no separate formatting hook.

### Registering Hooks {#registering-hooks}

Register built-in or custom hooks under `perSystem.pre-commit.settings.hooks`. Each attribute name becomes the hook ID used on the command line. A hook needs `enable = true` to be included.

```nix
perSystem = {lib, pkgs, ...}: {
  git-hooks.enable = true;

  pre-commit.settings.hooks = {
    # A built-in git-hooks.nix hook.
    check-merge-conflicts = {
      enable = true;
      stages = ["pre-commit"];
    };

    # A custom hook; assumes the project supports nix run .#tests -- run.
    project-tests = {
      enable = true;
      name = "Project tests";
      entry = "${lib.getExe pkgs.nix} --extra-experimental-features 'nix-command flakes' run .#tests -- run";
      pass_filenames = false;
      always_run = true;
      stages = ["pre-push"];
    };
  };
};
```

Use absolute Nix-provided executable paths in custom `entry` values so Git can run them outside the devshell.

By default, matching filenames are appended to the command; `pass_filenames = false` disables that for whole-project commands. File-oriented hooks can narrow their input with options such as `files` (a regular expression) and `types`. `always_run = true` makes a hook run even when there where no changes to any files that where selected by input filter options.

A hook without explicit `stages` inherits `pre-commit.settings.default_stages`, which defaults to `["pre-commit"]`. To register a hook only for explicit manual runs, set its `stages = ["manual"]`. To disable the module's default check, set `pre-commit.settings.hooks.flake-check.enable = lib.mkForce false`.

### Hook Stages and Automatic Execution {#hook-stages}

The supported git stages are:

| Stage                | When Git invokes it                                           |
| -------------------- | ------------------------------------------------------------- |
| `pre-commit`         | Before creating a commit.                                     |
| `pre-merge-commit`   | Before creating a merge commit.                               |
| `prepare-commit-msg` | Before editing the commit message.                            |
| `commit-msg`         | To validate the commit message.                               |
| `post-commit`        | After creating a commit.                                      |
| `pre-push`           | Before pushing to a remote.                                   |
| `post-checkout`      | After checkout or switch.                                     |
| `post-merge`         | After a merge.                                                |
| `post-rewrite`       | After commands that rewrite commits, such as amend or rebase. |
| `pre-rebase`         | Before a rebase.                                              |
| `manual`             | Never invoked automatically by Git.                           |

`manual` is not installed as a Git hook.

### Running Hooks Manually {#running-hooks-manually}

Run the wrapper from your repository:

```bash
# Inside the devshell:
run-git-hooks

# Or without entering the devshell:
nix run .#run-git-hooks
```

The wrapper runs the hook stages specified in `git-hooks.runStages`.

```nix
perSystem = {
  git-hooks = {
    enable = true;
    runStages = ["pre-push"];
  };
};
```

For each stage it invokes the configured runner with `run --all-files --config <generated-config> --hook-stage <stage>`. This checks all Git-tracked files rather than only staged changes, while still respecting each hook's stage and file filters. It stops at the first failing stage. A hook registered for multiple selected stages can run more than once.

> [!warning]
> `run-git-hooks` does not forward command-line arguments. `run-git-hooks --hook-stage pre-push` does **not** restrict execution to `pre-push`. Use the direct runner below or change `git-hooks.runStages`.

> There are three separate controls:
>
> | Setting                                 | Controls                                                                                           |
> | --------------------------------------- | -------------------------------------------------------------------------------------------------- |
> | `pre-commit.settings.hooks.<id>.stages` | Which stages a hook belongs to, and therefore which Git hooks are installed.                       |
> | `pre-commit.settings.default_stages`    | Stages inherited by hooks that omit `stages`.                                                      |
> | `git-hooks.runStages`                   | Which stages `run-git-hooks` invokes, in order; does not change hook registration or installation. |

### Skip Hooks {#skip-hooks}

In rare cases, skip one hook by ID or bypass the hooks for a Git operation:

```bash
SKIP=flake-check git push

git commit --no-verify -m "Commit message"
git push --no-verify
```

> [!warning]
> Use sparingly. `git commit --no-verify` bypasses `pre-commit` and `commit-msg`, not every possible stage. Skipping local hooks does not disable any separately configured CI checks.

## References {#references}

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [numtide/devshell](https://github.com/numtide/devshell)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix)
- [direnv Documentation](https://direnv.net/)
- [mightyiam/files](https://github.com/mightyiam/files)
