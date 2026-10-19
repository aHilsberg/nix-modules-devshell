---
role:
    - developers
topic:
    - nix
    - formatting
type: reference
last-substantial-update: "2026-10-18"
---

# Nix Module {#nix}

## Formatting {#nix-formatting}

Enabling `nix.enable` registers the formatter selected by `nix.formatter`: `nixfmt` by default, or Alejandra. It
also registers `deadnix --fail` as a non-rewriting dead-code check.

Neither formatter reads EditorConfig natively. The module evaluates EditorConfig against the representative
root-level path `flake.nix` and bakes the result into the formatter:

- `nixfmt` uses a numeric `indent_size`.
- Alejandra uses tabs for `indent_style = tab`, four spaces for `indent_size = 4`, and two spaces otherwise.
- Other [common EditorConfig settings](../Formatting.md#editorconfig) are not mapped; `deadnix` does not consume
  formatting settings.

Rules matching `flake.nix` become one project-wide policy for every `*.nix` file. Rules for specific real paths
and nested `.editorconfig` files do not apply. After changing `.editorconfig`, reevaluate/rebuild the formatter and
reload an existing development shell, for example with `direnv reload`.
