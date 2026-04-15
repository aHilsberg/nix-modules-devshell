{lib, ...}: {
  options = {
    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional explicit shell name.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Packages available in this shell.";
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
      description = "Environment variables exported in the shell.";
    };

    build.shell = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      description = "Final built shell derivation.";
    };
  };

  config.build.shell = let
    devshellConfig =
      builtins.intersectAttrs
      (lib.functionArgs pkgs.devshell.mkShell)
      config;
  in
    pkgs.devshell.mkShell devshellConfig;
}
