{
    customPkgs,
    lib,
    ...
}: {
    startup = {
        file-generation = {
            text = lib.getExe customPkgs.generate-nix-managed-files;
        };
    };
}
