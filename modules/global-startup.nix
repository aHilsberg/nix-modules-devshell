{...}: {
    flake-parts-lib,
    lib,
    ...
}: {
    options.perSystem = flake-parts-lib.mkPerSystemOption ({...}: {
        options = {
            # types matching startup options https://github.com/numtide/devshell/blob/main/modules/devshell.nix
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
                    A list of scripts to execute on startup of every devshell.
                '';
            };
        };
    });
}
