---
role:
    - developers
topic:
    - yaml
    - formatting
type: reference
last-substantial-update: "2026-10-18"
---

# YAML Module {#yaml}

## Formatting {#yaml-formatting}

Enabling `yaml.enable` registers `deno fmt` for `*.yaml` and `*.yml`.

Deno does not read EditorConfig natively. The module evaluates EditorConfig against the representative root-level
path `any.yaml` and generates a Deno configuration. It supports all
[common EditorConfig settings](../Formatting.md#editorconfig): `indent_style`, `indent_size` or `tab_width`, and
`max_line_length`. Missing, disabled, or invalid values are omitted so Deno can use its defaults.

Rules matching `any.yaml` become one policy for both `*.yaml` and `*.yml`. Rules for `.yml` only, specific real
paths, and nested `.editorconfig` files do not apply. The generated configuration is passed explicitly and is not
merged with a discovered project Deno configuration. After changing `.editorconfig`, reevaluate/rebuild the
formatter and reload an existing development shell, for example with `direnv reload`.
