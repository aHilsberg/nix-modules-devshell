{
  lib,
  projectLib,
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  options.formatting = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable formatting with treefmt
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.formatting.enabled {
      treefmt = {
        pkgs = pkgs;
        # adds `treefmt` check so that formatter runs on `nix flake check` (sandboxed: no writes)
        flakeCheck = projectLib.mkDevShellDefault true;
        # adds `treefmt` as formatter, `nix fmt` starts all formatters registered in `treefmt`
        flakeFormatter = projectLib.mkDevShellDefault true;
      };
    })
    (lib.mkIf (!config.formatting.enabled) {
      treefmt = {
        flakeCheck = lib.mkDefault false;
        flakeFormatter = lib.mkDefault false;
      };
    })
  ];
}
