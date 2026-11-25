---
audience:
    - developer
type: reference
topic:
    - rust
    - formatting
last-substantial-update: "2026-11-21"
---

# Rust Module {#rust}

## Available Commands {#rust-commands}

After entering the development shell, these commands are available:

| Command        | Purpose                               |
| -------------- | ------------------------------------- |
| `rustc`        | Compile Rust code                     |
| `cargo`        | Build, test, and manage Rust projects |
| `cargo clippy` | Lint Rust code                        |
| `cargo fmt`    | Format a Cargo project                |
| `rustfmt`      | Format individual Rust files          |
| `cargo expand` | Inspect macro and derive expansions   |

Run linting and [macro expansion](https://github.com/dtolnay/cargo-expand) explicitly:

```bash
cargo clippy # NOTE: Clippy is not registered as a formatter.
cargo expand
```

## Formatting {#rust-formatting}

Enabling `rust.enable` registers `rustfmt` for `*.rs`.

Rustfmt does not read EditorConfig natively. The module evaluates EditorConfig against the representative root-level
path `rust.rs` and passes mapped values as rustfmt configuration overrides. It supports all
[common EditorConfig settings](../Formatting.md#editorconfig): `indent_style`, `indent_size` or `tab_width`, and
`max_line_length`. It additionally maps `end_of_line = lf` or `crlf`. Missing, disabled, or invalid values are omitted.
Mapped values take precedence while the project's other `rustfmt.toml` settings are preserved.

Rules matching `rust.rs` become one project-wide policy for every `*.rs` file. Rules for specific real paths
and nested `.editorconfig` files do not apply. After changing `.editorconfig`, reevaluate/rebuild the formatter and
reload an existing development shell, for example with `direnv reload`.

## Snapshot Testing {#rust-snapshot-testing}

Additionally, enable snapshot testing tools:

```nix
perSystem = {
    devshells.default = {
        rust.enable = true;
        rust.testing.snapshots = true;  # Adds cargo-insta
    };
};
```

| Package         | Command       | Description                      |
| --------------- | ------------- | -------------------------------- |
| **cargo-insta** | `cargo insta` | CLI for managing Insta snapshots |

See the [Insta CLI documentation](https://insta.rs/docs/cli/) for more commands, including accepting or rejecting snapshots.
