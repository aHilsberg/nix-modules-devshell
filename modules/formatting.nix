{
  flake-parts-lib,
  lib,
  projectLib,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    pkgs,
    config,
    ...
  }: {
    options.formatting = {
      enable = lib.mkEnableOption "formatting with treefmt";
    };

    config = lib.mkMerge [
      (lib.mkIf config.formatting.enable {
        treefmt = {
          pkgs = pkgs;
          # adds `treefmt` check so that formatter runs on `nix flake check` (sandboxed: no writes)
          flakeCheck = projectLib.mkDevShellDefault true;
          # adds `treefmt` as formatter, `nix fmt` starts all formatters registered in `treefmt`
          flakeFormatter = projectLib.mkDevShellDefault true;
        };
      })
      (lib.mkIf (!config.formatting.enable) {
        treefmt = {
          flakeCheck = lib.mkDefault false;
          flakeFormatter = lib.mkDefault false;
        };
      })
    ];
  });
}
