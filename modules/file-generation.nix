{inputs, ...}: {
  imports = [
    inputs.files.flakeModules.default
  ];

  perSystem = {config, ...}: {
    packages.generate-nix-managed-files = config.files.writer.drv;
  };
}
