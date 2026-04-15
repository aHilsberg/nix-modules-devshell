# Getting Started

This guide explains how to use the nix-modules-devshell development environment in your projects.

## Entering the Development Shell

### With direnv (Recommended)

If you have direnv installed and configured:

```bash
cd <project-directory>
direnv allow  # Only required the first time
# The environment activates automatically
```

### Without direnv

```bash
cd <project-directory>
nix develop
```

This provides all tools, SDKs, and configures environment variables automatically.

## Formatting Code

The development environment uses **treefmt** (via `nix fmt`) as a unified wrapper for all formatters. This ensures consistent formatting across different file types and languages.

### Format All Files

```bash
nix fmt
```

### Format Specific Files

```bash
nix fmt -- path/to/file.nix path/to/other.md
```

### Check Formatting Without Modifying (CI)

```bash
nix fmt -- --fail-on-change
# or
nix flake check
```

### Passing Options to the Formatter

Arguments after `--` are forwarded to the underlying formatter:

```bash
nix fmt -- --check .
nix fmt -- --quiet
```

**Note:** The forwarded arguments must be supported by the formatter configured in your flake.

## Nix-Managed Files

Some files in your project may be generated and managed by Nix. These files are **read-only** and should not be edited manually.

### How It Works

The `files` module (via `mightyiam/files`) allows declaring files that should be generated from Nix expressions. This is useful for:

- `.gitignore` files with consistent entries
- Configuration files that should stay in sync with Nix definitions
- Any file that should be derived from your flake configuration

### Regenerating Managed Files

To regenerate all Nix-managed files:

```bash
nix run .#generate-nix-managed-files
```

### CI Check

A check is included that fails if Nix-managed files have been manually modified:

```bash
nix flake check
```

If you see an error about managed files being modified, regenerate them with the command above and commit the changes.

**Important:** Nix-managed files are read-only. Any manual changes will be overwritten when regenerating and will cause CI to fail.

## Available Modules

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

### Enabling Modules

In your devshell configuration:

```nix
devshells.default = {
  dotnet.enable = true;
  json.enable = true;
  markdown.enable = true;
  yaml.enable = true;
  xml.enable = true;
  # ...
};
```

## Git Hooks

Git hooks are automatically configured when both `git-hooks.enable` and `formatting.enable` are set to `true`. The pre-commit hook runs formatters on staged files before each commit.

### Enabling Git Hooks

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

### How It Works

1. When entering the development shell, Git hooks are automatically installed
2. Before each `git commit`, the treefmt hook runs on staged files
3. Changed files are automatically formatted
4. If formatting changes were made, you must re-stage and commit again

### Configured Hooks

The following pre-commit hooks are configured:

| Hook      | Description                      |
| --------- | -------------------------------- |
| `treefmt` | Runs treefmt on all staged files |

### Running Hooks Manually

```bash
# Format all files (same as what hooks do)
nix fmt

# Check without modifying (as in CI)
nix fmt -- --fail-on-change
```

### Skip Hooks (Emergency Only)

In rare cases, you can skip hooks:

```bash
git commit --no-verify -m "Commit message"
```

**Note:** Use sparingly. CI will still check formatting.

## Useful Commands

| Command                                | Description                        |
| -------------------------------------- | ---------------------------------- |
| `nix develop`                          | Enter the development shell        |
| `nix fmt`                              | Format all files                   |
| `nix fmt -- --fail-on-change`          | Check formatting without modifying |
| `nix flake check`                      | Run all checks (formatting, tests) |
| `nix run .#generate-nix-managed-files` | Regenerate Nix-managed files       |
| `direnv allow`                         | Allow direnv for current directory |
| `direnv reload`                        | Reload the development environment |

## Troubleshooting

### Environment Not Activating with direnv

1. Ensure direnv is installed: `direnv --version`
2. Ensure the shell hook is configured (see [Installation](./installation.md))
3. Run `direnv allow` in the project directory
4. Check for errors with `direnv status`

### Formatting Fails

1. Ensure you're in the development shell
2. Check which files are failing: `nix fmt -- --fail-on-change`
3. Run `nix fmt` to fix formatting issues

### Nix-Managed File Check Fails

1. Don't manually edit Nix-managed files
2. Regenerate with: `nix run .#generate-nix-managed-files`
3. Commit the regenerated files

## References

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [numtide/devshell](https://github.com/numtide/devshell)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [direnv Documentation](https://direnv.net/)
- [mightyiam/files](https://github.com/mightyiam/files)
