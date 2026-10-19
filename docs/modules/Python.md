---
role:
    - developers
topic:
    - python
    - formatting
type: reference
last-substantial-update: "2026-10-18"
---

# Python Module {#python}

## Formatting {#python-formatting}

Enabling `python.enable` registers `ruff check --fix` followed by `ruff format` for `*.py` and `*.pyi`.

Ruff does not read EditorConfig natively. The module evaluates EditorConfig against the representative root-level
path `python.py` and passes mapped values as Ruff configuration overrides. It supports all
[common EditorConfig settings](../Formatting.md#editorconfig): `indent_style`, `indent_size` or `tab_width`, and
`max_line_length`. It additionally maps `end_of_line = lf` or `crlf`. Numeric values outside Ruff's accepted ranges
are ignored. Mapped values take precedence while Ruff continues to discover the project's other Ruff settings and
lint rules.

Rules matching `python.py` become one policy for every `*.py` and `*.pyi` file. Rules for `.pyi` only, specific
real paths, and nested `.editorconfig` files do not apply. After changing `.editorconfig`, reevaluate/rebuild the
formatter and reload an existing development shell, for example with `direnv reload`.
