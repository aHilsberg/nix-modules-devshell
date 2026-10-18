---
role:
  - maintainers
topic:
  - nix-conventions
type: convention
last-substantial-update: "2026-10-18"
---

# Nix conventions in `nix-modules-devshell`

`nix-modules-devshell` follows the generic convention below for the project library and package set.

## Generic convention

### Project library (`lib.nix`)

Every project with its own nix functionality library provides a `lib.nix` at the repository root.

`lib.nix` is a flake-parts module. It:
- finds and imports library fragments, usually files ending in `*.lib.nix`;
- merges their exports into a shared attribute set (via the module system or a custom merge);
- exposes the merged project library itself as the flake-parts module argument `projectLib`.

The functionality be comes availble to all project local flake-parts modules via:
```nix
{projectLib, ...}: {
  # projectLib.<namespace>.<function>
}
```

### Package set (`pkgs.nix`)

`pkgs` denotes the complete package set that a project is allowed to reference. It does not necessarily consist only of unmodified `nixpkgs`; through overlays, it can:
- provide additional packages;
- override existing packages;
- selectively hide packages or attributes;
- apply shared package configuration across the project.

Every project standardizes the creation of this package set through `projectLib.mkPkgs`. The implementation belongs in `lib.nix`, which:
1. collects the overlays registered in the flake;
2. imports `nixpkgs` for the respective system with these overlays;
3. provides the resulting package set through the flake-parts argument `pkgs` for each system;
4. also exports a function such as `projectLib.mkPkgs` when the same package set is needed outside `perSystem`.

All flake-parts modules should use this provided `pkgs` instead of importing `nixpkgs` themselves with a different overlay or package configuration.

---

Overlays are commonly registered through `flake.overlays`. Example:

```nix
flake.overlays.devshell = inputs.devshell.overlays.default;
```

This makes additional packages and customizations part of the centrally created project package set.

## Project-specific conventions

### Library attribute sets

`projectLib` is available to this project's flake-parts modules as a top-level module argument. It contains the internal project library, including `projectLib.mkPkgs`.

#### Adding library functions

Add internal project functions to the `projectLib` attribute set in `lib.nix`. They then become available to internal modules as `projectLib.<name>` without becoming part of the exported flake module's public interface.

### Package set

The complete project package set follows the shared Nix conventions. All overlays registered in `flake.overlays` are applied to it.

Inside `perSystem`, use only the provided `pkgs` module argument.

Outside `perSystem`, use `projectLib.mkPkgs system` when a package set for a specific system is required.

Do not import `inputs.nixpkgs` separately.
