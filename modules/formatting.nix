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
      (lib.filterAttrs (_: opt: (opt.visible or true) && !(opt.readOnly or false))
        (treefmtOpts.settings.type.getSubOptions []))
      ["_module" "global"];

    visibleProgramOptions =
      lib.mapAttrs (
        _: progOpts:
          lib.filterAttrs (_: opt: (opt.visible or true) && !(opt.readOnly or false))
          progOpts
      )
      (lib.filterAttrs (_: subopts: subopts.enable.visible or true)
        treefmtOpts.programs);
  in {
    options.formatting = {
      enable = lib.mkEnableOption "formatting with treefmt";

      excludes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          # Visual Studio Code
          ".vscode/**"
          # JetBrains IDEs (IntelliJ IDEA, WebStorm, PyCharm, Rider, etc.)
          ".idea/**"
          # JetBrains Fleet
          ".fleet/**"
          # Visual Studio
          ".vs/**"
          # Eclipse
          ".settings/**"
          # Zed
          ".zed/**"
          # direnv
          ".direnv/**"
        ];
        description = ''
          A global list of paths to exclude from all formatters. Supports glob patterns.
        '';
      };
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
              settings.excludes = config.formatting.excludes;
              programs.prettier.package = lib.mkDefault pkgs.prettier;
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
