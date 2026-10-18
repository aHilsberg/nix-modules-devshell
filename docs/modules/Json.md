---
role:
  - developers
topic:
  - json
  - formatting
type: reference
last-substantial-update: "2026-10-18"
---

# JSON Module {#json}

## Formatting {#json-formatting}

Enabling `json.enable` registers Prettier for `*.json` and `*.jsonc`.

Prettier reads EditorConfig natively for each actual input path. It supports all
[common EditorConfig settings](../Formatting.md#editorconfig) and `end_of_line`. Nested `.editorconfig` files and
file-specific sections apply on the next formatter run without rebuilding or reloading the development shell.
Prettier configuration files take precedence over translated EditorConfig values.
