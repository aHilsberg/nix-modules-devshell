{
    lib,
    projectLib,
    pkgs,
    config,
    ...
}: let
    shellOptions = {
        name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional explicit shell name.";
        };

        # https://github.com/numtide/devshell/blob/main/modules/devshell.nix
        startup = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
                options = {
                    text = lib.mkOption {
                        type = lib.types.str;
                        description = ''
                            Script to run.
                        '';
                    };

                    deps = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = [];
                        description = ''
                            A list of other steps that this one depends on.
                        '';
                    };
                };
            });
            default = {};
            description = ''
                A list of scripts to execute on startup.
            '';
        };

        packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "Packages available in this shell.";
        };

        # https://github.com/numtide/devshell/blob/main/modules/env.nix
        env = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
                options = {
                    name = lib.mkOption {
                        type = lib.types.str;
                        description = "Name of the environment variable";
                    };

                    value = lib.mkOption {
                        type = with lib.types;
                            nullOr (oneOf [str int bool package]);
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

        # https://github.com/numtide/devshell/blob/main/modules/commands.nix
        commands = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
                options = {
                    name = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = ''
                            Name of this command. Defaults to attribute name in commands.
                        '';
                    };

                    category = lib.mkOption {
                        type = lib.types.str;
                        default = "[general commands]";
                        description = ''
                            Set a free text category under which this command is grouped
                            and shown in the help menu.
                        '';
                    };

                    help = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = ''
                            Describes what the command does in one line of text.
                        '';
                    };

                    command = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = ''
                            If defined, it will add a script with the name of the command, and the
                            content of this value.

                            By default it generates a bash script, unless a different shebang is
                            provided.
                        '';
                        example = ''
                            #!/usr/bin/env python
                            print("Hello")
                        '';
                    };

                    package = lib.mkOption {
                        type = lib.types.nullOr projectLib.types.strOrPackage;
                        default = null;
                        description = ''
                            Used to bring in a specific package. This package will be added to the
                            environment.
                        '';
                    };
                };
            });
            default = [];
            description = "Commands shown in menu of devshell.";
        };
    };

    # numtide/devshell expects:
    # - `env`, `commands` at the top level
    # - `startup`, `packages`, `name` under `devshell.*
    devshellConfig = {
        env = config.env;
        commands = config.commands;
        devshell =
            {
                startup = config.startup;
                packages = config.packages;
            }
            // lib.optionalAttrs (config.name != null) {
                name = config.name;
            };
    };
in {
    options =
        shellOptions
        // {
            build.shell = lib.mkOption {
                type = lib.types.package;
                internal = true;
                readOnly = true;
                description = "Final built shell derivation.";
            };
        };

    config.build.shell = pkgs.devshell.mkShell devshellConfig;
}
