{
  flake-parts-lib,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.files.flakeModules.default
  ];

  perSystem = {config, ...}: {
    packages.generate-nix-managed-files = config.files.writer.drv;
  };
}
