{ projectLib, lib, ... }: {
    perSystem =
        {
            pkgs,
            system,
            ...
        }:
        {
            tests =
                {
                    test,
                    that,
                    should,
                    utils,
                    ...
                }:
                let
                    testLib = projectLib.testing {
                        inherit
                            that
                            should
                            utils
                            pkgs
                            system
                            ;
                    };
                    inherit (testLib) asserts devshell;

                    helloStartupModule.perSystem.devshells.default.startup.hello.text = ''
                        echo "hello from startup"
                    '';
                    helloCommandModule.perSystem.devshells.default.commands = [
                        {
                            name = "hello-command";
                            command = ''
                                echo "hello from command"
                            '';
                            help = "Print a test message";
                        }
                    ];
                in
                {
                    core = {
                        formatting-workspace-providesIsolatedWritableHome = test.asserts {
                            tags = [ "formatting" ];
                            # First assert normally snapshots the formatter output, but we only care about it running
                            # successfully.
                            assertions = lib.tail (
                                asserts.formatingAsExpected {
                                    name = "core-formatting-workspace-providesIsolatedWritableHome";
                                    snapshotPathRelativeTo = ./.;
                                    filetreeToFormat = pkgs.writeTextDir "sample.txt" "unchanged\n";
                                    formatterModule.perSystem.formatter = pkgs.writeShellApplication {
                                        name = "check-formatter-home";
                                        runtimeInputs = [ pkgs.coreutils ];
                                        text = ''
                                            if [[ "$HOME" != "$PWD/"* || ! -d "$HOME" || ! -w "$HOME" ]]; then
                                                printf '%s\n' 'Formatter HOME must be an isolated writable directory in the workspace.' >&2
                                                exit 1
                                            fi
                                            if [[ -e "$HOME/formatter-probe" ]]; then
                                                printf '%s\n' 'Formatting passes must not share HOME state.' >&2
                                                exit 1
                                            fi
                                            printf 'writable\n' > "$HOME/formatter-probe"
                                        '';
                                    };
                                }
                            );
                        };
                        startup-echoScript-writesExpectedOutput = test.asserts {
                            assertions = [
                                (that
                                    (devshell.stdout {
                                        name = "startup-echo-script";
                                        module = helloStartupModule;
                                        command = [ "true" ];
                                    })
                                    (
                                        should.haveSameContents {
                                            expected = pkgs.writeText "startup-echo-script-expected" ''
                                                hello from startup
                                            '';
                                        }
                                    )
                                )
                            ];
                        };
                        command-configuredCommand-writesExpectedOutput = test.asserts {
                            assertions = [
                                (that
                                    (devshell.stdout {
                                        name = "configured-devshell-command";
                                        module = helloCommandModule;
                                        command = [ "hello-command" ];
                                    })
                                    (
                                        should.haveSameContents {
                                            expected = pkgs.writeText "configured-devshell-command-expected" ''
                                                hello from command
                                            '';
                                        }
                                    )
                                )
                            ];
                        };
                    };
                };
        };
}
