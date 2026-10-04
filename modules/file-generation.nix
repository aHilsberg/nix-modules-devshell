{localInputs, ...}: {...}: {
    imports = [
        "${localInputs.files}/flake-module.nix"
    ];

    perSystem = {config, ...}: {
        # using in devshell-submodule
        packages.generate-nix-managed-files = config.files.writer.drv;
    };
}
