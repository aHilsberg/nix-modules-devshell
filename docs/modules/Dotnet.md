---
role:
  - developers
topic:
  - dotnet
  - snapshot-testing
type: reference
last-substantial-update: "2026-10-18"
---

# .NET Module {#dotnet}

## Formatting {#dotnet-formatting}

Enabling `dotnet.enable` registers JetBrains ReSharper `cleanupcode` for `*.cs`, `*.csproj`, and
`Directory.Packages.props`; `legacy/**` is excluded.

`cleanupcode` reads EditorConfig natively for each actual input path. It supports all
[common EditorConfig settings](../Formatting.md#editorconfig), plus `insert_final_newline`, common .NET coding
conventions, and ReSharper-specific formatting and cleanup properties. Nested `.editorconfig` files and
file-specific sections apply without rebuilding or reloading the development shell.

## Packages {#net-packages}

When `dotnet.enable = true`, the following packages are automatically available:

| Package                  | Command           | Description                               |
| ------------------------ | ----------------- | ----------------------------------------- |
| **dotnet-outdated**       | `dotnet-outdated`  | Display and update outdated NuGet packages |
| **report-generator**     | `reportgenerator` | Generate coverage reports from XML files   |
| **jetbrains-globaltools** | `jb`              | JetBrains code cleanup and formatting      |

## Snapshot Testing {#snapshot-testing}

Additionally, enable snapshot testing tools:

```nix
perSystem = {
    devshells.default = {
        dotnet.enable = true;
        dotnet.testing.snapshots = true;  # Adds Verify.Terminal
    };
};
```

| Package             | Command         | Description                      |
| ------------------- | --------------- | -------------------------------- |
| **verify-terminal** | `dotnet-verify` | CLI for managing Verify snapshots |
