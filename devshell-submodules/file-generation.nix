{
    perSysCfg,
    lib,
    ...
}: {
    startup = {
        file-generation = {
            text = lib.getExe perSysCfg.packages.generate-nix-managed-files;
        };
    };
}
