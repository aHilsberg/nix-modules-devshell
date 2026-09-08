# Nix conventions in `nix-modules-devshell`

`nix-modules-devshell` follows the conventions for the project library and package set.

## Library attribute sets

`projectLib` is available to this project's flake-parts modules as a top-level module argument. It contains the internal project library, including `projectLib.mkPkgs`.

### Adding library functions

Add internal project functions to the `projectLib` attribute set in `lib.nix`. They then become available to internal modules as `projectLib.<name>` without becoming part of the exported flake module's public interface.

## Package set

The complete project package set follows the shared Nix conventions. All overlays registered in `flake.overlays` are applied to it.

- Inside `perSystem`, use only the provided `pkgs` module argument.
- Outside `perSystem`, use `projectLib.mkPkgs system` when a package set for a specific system is required.
- Do not import `inputs.nixpkgs` separately.
