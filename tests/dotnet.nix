{
    self,
    projectLib,
    lib,
    ...
}: {
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
            inherit (testLib) asserts devshell;

            dotnetModule.perSystem = {
                packages = {
                    inherit (self.packages.${system}) report-generator dotnet-outdated jetbrains-resharper-cleanup verify-terminal;
                };
                devshells.default.dotnet.enable = true;
            };
            formatterModule = lib.recursiveUpdate dotnetModule {
                perSystem.formatting.enable = true;
            };

            dotnet8Sdk = pkgs.dotnetCorePackages.sdk_8_0;
        in {
            dotnet = {
                formatting-twoSpaceEditorConfig-formatsWithTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "dotnet-formatting-twoSpaceEditorConfig-formatsWithTwoSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/data/cs;
                        repoContent.editorConfig = ''
                            root = true

                            [*.cs]
                            indent_style = space
                            indent_size = 2
                            end_of_line = lf
                        '';
                    };
                };
                formatting-fourSpaceEditorConfig-formatsWithFourSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "dotnet-formatting-fourSpaceEditorConfig-formatsWithFourSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/data/cs;
                        repoContent.editorConfig = ''
                            root = true

                            [*.cs]
                            indent_style = space
                            indent_size = 4
                            end_of_line = lf
                        '';
                    };
                };
                formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "dotnet-formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/data/cs;
                        repoContent.editorConfig = ''
                            root = true

                            [*]
                            indent_style = space
                            indent_size = 4
                            end_of_line = lf

                            [*.cs]
                            indent_size = 2
                        '';
                    };
                };

                formatting-customDotsettings-expandsExpressionBody = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "dotnet-formatting-customDotsettings-expandsExpressionBody";
                        snapshotPathRelativeTo = ./.;
                        formatterModule = lib.recursiveUpdate formatterModule {
                            # Loose files cannot discover the solution's settings layer.
                            perSystem.devshells.default.formatting.treefmt.settings.formatter.jb.options = ["--settings=UmeCore.sln.DotSettings"];
                        };
                        filetreeToFormat = ./fixtures/data/dotnet-expression-body;
                        repoContent.files."UmeCore.sln.DotSettings" = builtins.readFile ./fixtures/data/dotnet-settings/UmeCore.sln.DotSettings;
                    };
                };
                sdk-customPackage-reportsSelectedVersion = test.asserts {
                    assertions = [
                        (that (devshell.stdout {
                            name = "dotnet-selected-sdk-version";
                            module = lib.recursiveUpdate dotnetModule {
                                perSystem.devshells.default.dotnet.sdk = dotnet8Sdk;
                            };
                            command = [
                                "sh"
                                "-c"
                                ''
                                    dotnet --info |
                                        while IFS= read -r line; do
                                            case "$line" in
                                                " Version:"*)
                                                    set -- $line
                                                    printf '%s\n' "$2"
                                                    break
                                                    ;;
                                            esac
                                        done
                                ''
                            ];
                        }) (should.haveSameContents {
                            expected = pkgs.writeText "dotnet-selected-sdk-version-expected" ''
                                ${dotnet8Sdk.version}
                            '';
                        }))
                    ];
                };
                snapshots-enabled-runsVerifyCommand = test.asserts {
                    assertions = [
                        (that (devshell.stdout {
                            name = "dotnet-verify-enabled";
                            module = lib.recursiveUpdate dotnetModule {
                                perSystem.devshells.default.dotnet.testing.snapshots = true;
                            };
                            command = [
                                "sh"
                                "-c"
                                ''
                                    dotnet verify --help >/dev/null 2>&1
                                    printf 'available\n'
                                ''
                            ];
                        }) (should.haveSameContents {
                            expected = pkgs.writeText "dotnet-verify-enabled-expected" ''
                                available
                            '';
                        }))
                    ];
                };
                snapshots-disabled-omitsVerifyCommand = test.asserts {
                    assertions = [
                        (that (devshell.stdout {
                            name = "dotnet-verify-disabled";
                            module = dotnetModule;
                            command = [
                                "sh"
                                "-c"
                                ''
                                    if dotnet verify --help >/dev/null 2>&1; then
                                        printf 'available\n'
                                    else
                                        printf 'unavailable\n'
                                    fi
                                ''
                            ];
                        }) (should.haveSameContents {
                            expected = pkgs.writeText "dotnet-verify-disabled-expected" ''
                                unavailable
                            '';
                        }))
                    ];
                };
            };
        };
    };
}
