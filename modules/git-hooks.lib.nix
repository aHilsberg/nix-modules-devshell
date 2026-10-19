{ ... }: {
    modules.flake.gitHooks =
        { localInputs, ... }:
        {
            flake-parts-lib,
            lib,
            ...
        }:
        {
            imports = [
                localInputs.git-hooks-nix.flakeModule
            ];

            options.perSystem = flake-parts-lib.mkPerSystemOption (
                {
                    config,
                    pkgs,
                    ...
                }:
                {
                    options.git-hooks = {
                        enable = lib.mkEnableOption "Git hooks for this project";

                        runStages = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [
                                "manual"
                                "pre-commit"
                                "pre-push"
                            ];
                            description = ''
                                List of git hook stages to run when executing the manual `run-git-hooks` command.
                                Common stages include: "pre-commit", "pre-push"
                            '';
                            example = [
                                "pre-commit"
                                "pre-push"
                            ];
                        };
                    };

                    config = {
                        # see https://flake.parts/options/git-hooks-nix.html#options
                        pre-commit = lib.mkMerge [
                            {
                                check.enable = false; # no running hooks as a nix flake check, since hooks run nix flake check
                            }

                            (lib.mkIf config.git-hooks.enable (
                                lib.mkMerge [
                                    {
                                        settings.hooks = {
                                            flake-check = {
                                                enable = true;
                                                entry = "${lib.getExe pkgs.nix} --extra-experimental-features 'nix-command flakes' flake check";
                                                pass_filenames = false;
                                                stages = [ "pre-push" ];
                                            };
                                        };
                                    }
                                ]
                            ))
                        ];

                        packages.run-git-hooks = lib.mkDefault (
                            if config.git-hooks.enable then
                                (
                                    let
                                        preCommitConfig = config.pre-commit.settings;
                                        stageCommands = lib.concatMapStringsSep "\n" (stage: ''
                                            ${pkgs.lib.getExe preCommitConfig.package} run --all-files --config ${preCommitConfig.configFile} --hook-stage ${stage} || exit 1
                                        '') config.git-hooks.runStages;
                                        script = ''
                                            ${stageCommands}
                                        '';
                                    in
                                    pkgs.writeShellScriptBin "run-git-hooks" script
                                )
                            else
                                pkgs.emptyDirectory
                        );

                        gitignore.entries = lib.mkIf config.git-hooks.enable [ ".pre-commit-config.yaml" ];
                    };
                }
            );
        };

    modules.devshell.gitHooks =
        {
            customPkgs,
            perSysCfg,
            ...
        }:
        { lib, ... }: {

            commands = lib.mkIf perSysCfg.git-hooks.enable [
                {
                    name = "run-git-hooks";
                    package = customPkgs.run-git-hooks;
                    category = "development";
                    help = "Run the configured Git hooks.";
                }
            ];

            startup = lib.mkIf perSysCfg.git-hooks.enable {
                git-hooks = {
                    text = perSysCfg.pre-commit.installationScript;
                };
            };
        };
}
