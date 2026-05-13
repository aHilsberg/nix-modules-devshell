{lib, ...}: rec {
    mkDevShellDefault = lib.mkOverride 60;
    types = {
        strOrPackage = lib.types.either lib.types.str lib.types.package;
    };
}
