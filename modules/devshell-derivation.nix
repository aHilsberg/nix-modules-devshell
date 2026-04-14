{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  strOrPackage = lib.types.either lib.types.str lib.types.package;
in {
  options = {
    build.shell = lib.mkOption {
      type = lib.types.package;
      description = "The devshell derivation";
      internal = true;
    };

    env = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the environment variable";
          };

          value = lib.mkOption {
            type = with lib.types;
              nullOr (oneOf [
                str
                int
                bool
                package
              ]);
            default = null;
            description = "Shell-escaped value to set";
          };

          eval = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Like value but not evaluated by Bash. This allows to inject other
              variable names or even commands using the `$()` notation.
            '';
            example = "$OTHER_VAR";
          };

          prefix = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Prepend to PATH-like environment variables.

              For example name = "PATH"; prefix = "bin"; will expand the path of
              ./bin and prepend it to the PATH, separated by ':'.
            '';
            example = "bin";
          };

          unset = lib.mkEnableOption "unsets the variable";
        };
      });
      default = [];
      description = ''
        Add environment variables to the shell.
      '';
      example = lib.literalExpression ''
        [
          {
            name = "HTTP_PORT";
            value = 8080;
          }
          {
            name = "PATH";
            prefix = "bin";
          }
          {
            name = "XDG_CACHE_DIR";
            eval = "$PRJ_ROOT/.cache";
          }
          {
            name = "CARGO_HOME";
            unset = true;
          }
        ]
      '';
    };

    packages = lib.mkOption {
      type = lib.types.listOf strOrPackage;
      default = [];
      description = ''
        The set of packages to appear in the project environment.

        Those packages come from <https://nixos.org/NixOS/nixpkgs> and can be
        searched by going to <https://search.nixos.org/packages>
      '';
    };

    packagesFrom = lib.mkOption {
      type = lib.types.listOf strOrPackage;
      default = [];
      description = ''
        Add all the build dependencies from the listed packages to the
        environment.
      '';
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "devshell";
      description = ''
        Name of the shell environment. It usually maps to the project name.
      '';
    };
  };

  config = {
    build.shell =
      pkgs.devshell.mkShell
      # exclude internal module system and the build attribute itself from the config
      (lib.filterAttrs (n: v: n != "build" && n != "_module") config)
      // {
        prj_root_fallback = {
          eval = "$(git rev-parse --show-toplevel)";
        };
      };
  };
}
