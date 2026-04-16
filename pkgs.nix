{
    inputs,
    lib,
    self,
    ...
}: let
    # order by names to make it deterministic; order shouldn't matter!
    overlayNames = lib.sort lib.lessThan (builtins.attrNames self.overlays);
    overlaysAll = map (n: self.overlays.${n}) overlayNames;

    mkPkgs = system:
        import inputs.nixpkgs {
            inherit system;
            overlays = overlaysAll;
            config.allowUnfree = true;
        };
in {
    perSystem = {system, ...}: {
        # following https://flake.parts/system.html
        _module.args.pkgs = mkPkgs system;
    };
}
