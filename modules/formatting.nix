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
    options,
    ...
  }: let
    treefmtOpts = options.treefmt.type.getSubOptions [];

    visibleSettingsOptions =
      lib.removeAttrs
      (lib.filterAttrs (_: opt: opt.visible or true)
        (treefmtOpts.settings.type.getSubOptions []))
      ["_module" "global"];

    visibleProgramOptions =
      lib.filterAttrs (_: subopts: subopts.enable.visible or true)
      treefmtOpts.programs;
  in {
    options.formatting = {
      enable = lib.mkEnableOption "formatting with treefmt";
    };

    config = lib.mkMerge [
      {
        devshell-submodule-extension = [
          ({lib, ...}: {
            options.formatting.treefmt = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  settings = lib.mkOption {
                    type = lib.types.submodule {
                      freeformType = (pkgs.formats.toml {}).type;
                      options = visibleSettingsOptions;
                    };
                    default = {};
                    description = ''
                      treefmt settings configuration included in this devshell.
                    '';
                  };

                  programs = lib.mkOption {
                    type = lib.types.submodule {
                      options = visibleProgramOptions;
                    };
                    default = {};
                    description = ''
                      treefmt programs configuration included in this devshell.
                    '';
                  };
                };
              };
              default = {};
              description = ''
                treefmt configuration included in all devshells.
                This will be merged into the perSystem treefmt if formatting is enabled.
              '';
            };
          })
        ];
      }

      (lib.mkIf config.formatting.enable {
        treefmt = lib.mkMerge (
          [
            {
              pkgs = pkgs;
              flakeCheck = projectLib.mkDevShellDefault true;
              flakeFormatter = projectLib.mkDevShellDefault true;
            }
          ]
          ++ lib.mapAttrsToList
          (_: shellCfg: shellCfg.formatting.treefmt or {})
          config.devshells
        );
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
