{lib, ...}: rec {
    mkDevShellDefault = lib.mkOverride 60;
}
