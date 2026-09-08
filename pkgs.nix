{projectLib, ...}: {
    perSystem = {system, ...}: {
        # following https://flake.parts/system.html
        _module.args.pkgs = projectLib.mkPkgs system;
    };
}
