{
  flake-parts-lib,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.git-hooks-nix.flakeModule
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({config, ...}: {
    options.git-hooks = {
      enable = lib.mkEnableOption "Git hooks for this project";
    };

    config = lib.mkIf (config.git-hooks.enable && config.formatting.enable) {
      pre-commit.settings.hooks = {
        treefmt = {
          enable = true;
          packageOverrides.treefmt = config.treefmt.build.wrapper;
        };
      };
    };
  });
}
