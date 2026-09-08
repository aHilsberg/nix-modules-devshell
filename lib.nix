{
    inputs,
    lib,
    self,
    ...
}: let
    # order by names to make it deterministic; order shouldn't matter!
    overlayNames = lib.sort lib.lessThan (builtins.attrNames self.overlays);
    overlaysAll = map (n: self.overlays.${n}) overlayNames;

    projectLib = {
        mkPkgs = system:
            import inputs.nixpkgs {
                inherit system;
                overlays = overlaysAll;
                config.allowUnfree = true;
            };
        mkDevShellDefault = lib.mkOverride 60;
        types = {
            strOrPackage = lib.types.either lib.types.str lib.types.package;
        };
    };
in {
    _module.args.projectLib = projectLib;
}
