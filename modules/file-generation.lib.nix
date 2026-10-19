{ ... }: {
    modules.flake.fileGeneration = { localInputs, ... }: { ... }: {
        imports = [
            "${localInputs.files}/flake-module.nix"
        ];

        perSystem = { config, ... }: {
            # using in devshell-submodule
            packages.generate-nix-managed-files = config.files.writer.drv;
        };
    };
    
    modules.devshell.fileGeneration = { perSysCfg, ... }: { lib, ... }: {

        startup = {
            file-generation = {
                text = lib.getExe perSysCfg.packages.generate-nix-managed-files;
            };
        };
    };
}
