---
role:
    - developers
topic:
    - xml
    - formatting
type: reference
last-substantial-update: "2026-10-18"
---

# XML Module {#xml}

## Formatting {#xml-formatting}

Enabling `xml.enable` registers Prettier with the XML plugin for `*.xml` and `*.resx`.

Prettier reads EditorConfig natively for each actual input path. It supports all
[common EditorConfig settings](../Formatting.md#editorconfig) and `end_of_line`. Nested `.editorconfig` files and
file-specific sections apply on the next formatter run without rebuilding or reloading the development shell.
Prettier configuration files take precedence over translated EditorConfig values.
