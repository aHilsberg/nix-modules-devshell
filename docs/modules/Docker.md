---
role:
    - developers
topic:
    - docker
    - formatting
type: reference
last-substantial-update: "2026-10-18"
---

# Docker Module {#docker}

## Formatting {#docker-formatting}

Enabling `docker.enable` registers `dockerfmt` for Dockerfiles.

`dockerfmt` reads EditorConfig natively for each actual input path. Of the
[common EditorConfig settings](../Formatting.md#editorconfig), it supports `indent_size`. It additionally supports
`insert_final_newline` and the non-standard `space_redirects` property. Changes to `.editorconfig`, including
nested and path-specific rules, apply on the next formatter run without rebuilding or reloading the development
shell.
