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
  }: {
    options.formatting = {
      enable = lib.mkEnableOption "formatting with treefmt";
    };

    config = lib.mkMerge [
      {
        devshell-submodule-extension = [
          ({
            lib,
            config,
            ...
          }: {
            options.formatting.treefmt =
              lib.mkOption
              {
                type = lib.types.submodule (
                  let
                    treefmtOpts = options.treefmt.type.getSubOptions [];
                  in {
                    options = {
                      settings = lib.mkOption {
                        type = treefmtOpts.settings.type;
                        default = {};
                        description = ''
                          treefmt settings configuration included in this devshell.
                        '';
                      };

                      programs = lib.mkOption {
                        type = lib.types.submodule {
                          options = treefmtOpts.programs;
                        };
                        default = {};
                        description = ''
                          treefmt programs configuration included in this devshell.
                        '';
                      };
                    };
                  }
                );
              };
          })
        ];
      }

      # see https://flake.parts/options/treefmt-nix.html
      (lib.mkIf config.formatting.enable {
        treefmt = lib.mkMerge (
          [
            {
              pkgs = pkgs;

              # adds `treefmt` check so that formatter runs on `nix flake check` (sandboxed: no writes)
              flakeCheck = projectLib.mkDevShellDefault true;
              # adds `treefmt` as formatter, `nix fmt` starts all formatters registered in `treefmt`
              flakeFormatter = projectLib.mkDevShellDefault true;
            }
          ]
          ++ (
            lib.mapAttrsToList
            (_: shellCfg: shellCfg.formatting.treefmt or {})
            config.devshells
          )
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
