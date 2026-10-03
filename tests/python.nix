{
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

            formatterModule.perSystem = {
                formatting.enable = true;
                devshells.default.python.enable = true;
            };
        in {
            python = {
                formatting-twoSpaceIndent-formatsWithTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "python-formatting-twoSpaceIndent-formatsWithTwoSpaces";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/python-indent;
                        snapshotPathRelativeTo = ./.;
                        repoContent = {
                            editorConfig = ''
                                root = true

                                [*.{py,pyi}]
                                indent_style = space
                                indent_size = 2
                            '';
                        };
                    };
                };
                formatting-fourSpaceIndent-formatsWithFourSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "python-formatting-fourSpaceIndent-formatsWithFourSpaces";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/python-indent;
                        snapshotPathRelativeTo = ./.;
                        repoContent = {
                            editorConfig = ''
                                root = true

                                [*.{py,pyi}]
                                indent_style = space
                                indent_size = 4
                            '';
                        };
                    };
                };
                formatting-tabIndent-formatsWithTabs = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "python-formatting-tabIndent-formatsWithTabs";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/python-indent;
                        snapshotPathRelativeTo = ./.;
                        repoContent = {
                            editorConfig = ''
                                root = true

                                [*.{py,pyi}]
                                indent_style = tab
                            '';
                        };
                    };
                };
                formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "python-formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/python-indent;
                        snapshotPathRelativeTo = ./.;
                        repoContent = {
                            editorConfig = ''
                                root = true

                                [*]
                                indent_size = 4

                                [*.py]
                                indent_size = 2
                            '';
                        };
                    };
                };
                formatting-width40-wrapsLongLine = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "python-formatting-width40-wrapsLongLine";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/python-width;
                        snapshotPathRelativeTo = ./.;
                        repoContent = {
                            editorConfig = ''
                                root = true

                                [*.{py,pyi}]
                                max_line_length = 40
                            '';
                        };
                    };
                };
                formatting-noEditorConfig-usesRuffDefaults = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "python-formatting-noEditorConfig-usesRuffDefaults";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/python-indent;
                        snapshotPathRelativeTo = ./.;
                        repoContent = {};
                    };
                };
                interpreter-customPackage-runsSelectedVersion = test.asserts {
                    assertions = [
                        (that (devshell.stdout {
                            name = "python-selected-version";
                            module = {
                                perSystem.devshells.default.python = {
                                    enable = true;
                                    package = pkgs.python311;
                                };
                            };
                            command = [
                                "python"
                                "-c"
                                "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
                            ];
                        }) (should.haveSameContents {
                            expected = pkgs.writeText "python-selected-version-expected" ''
                                ${lib.versions.majorMinor pkgs.python311.version}
                            '';
                        }))
                    ];
                };
                interpreter-extraPackages-makesDependencyImportable = test.asserts {
                    assertions = [
                        (that (devshell.stdout {
                            name = "python-extra-package";
                            module = {
                                perSystem.devshells.default.python = {
                                    enable = true;
                                    extraPackages = pythonPackages: [pythonPackages.requests];
                                };
                            };
                            command = [
                                "python"
                                "-c"
                                "import requests; print(requests.__name__)"
                            ];
                        }) (should.haveSameContents {
                            expected = pkgs.writeText "python-extra-package-expected" ''
                                requests
                            '';
                        }))
                    ];
                };
            };
        };
    };
}
