{localInputs, ...}: {...}: {
    imports = [
        localInputs.files.flakeModules.default
    ];

    perSystem = {config, ...}: {
        # using in devshell-submodule
        packages.generate-nix-managed-files = config.files.writer.drv;
    };
}
