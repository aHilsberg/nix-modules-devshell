{projectLib, ...}: {
    perSystem = {
        pkgs,
        system,
        ...
    }: {
        tests = {
            test,
            that,
            should,
            utils,
            ...
        }: let
            testLib = projectLib.testing {inherit that should utils pkgs system;};
            inherit (testLib) devshell;

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
        in {
            core = {
                startup-echoScript-writesExpectedOutput = test.asserts {
                    assertions = [
                        (that (devshell.stdout {
                            name = "startup-echo-script";
                            module = helloStartupModule;
                            command = ["true"];
                        }) (should.haveSameContents {
                            expected = pkgs.writeText "startup-echo-script-expected" ''
                                hello from startup
                            '';
                        }))
                    ];
                };
                command-configuredCommand-writesExpectedOutput = test.asserts {
                    assertions = [
                        (that (devshell.stdout {
                            name = "configured-devshell-command";
                            module = helloCommandModule;
                            command = ["hello-command"];
                        }) (should.haveSameContents {
                            expected = pkgs.writeText "configured-devshell-command-expected" ''
                                hello from command
                            '';
                        }))
                    ];
                };
            };
        };
    };
}
