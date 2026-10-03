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
            asserts = (projectLib.testing {inherit that should utils pkgs system;}).asserts;
            formatterModule.perSystem = {
                formatting.enable = true;
                devshells.default.yaml.enable = true;
            };
        in {
            yaml = {
                formatting-twoSpaceEditorConfig-formatsWithTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "yaml-formatting-twoSpaceEditorConfig-formatsWithTwoSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/yaml-indent;
                        repoContent.editorConfig = ''
                            root = true

                            [*.yaml]
                            indent_style = space
                            indent_size = 2
                        '';
                    };
                };
                formatting-fourSpaceEditorConfig-formatsWithFourSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "yaml-formatting-fourSpaceEditorConfig-formatsWithFourSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/yaml-indent;
                        repoContent.editorConfig = ''
                            root = true

                            [*.yaml]
                            indent_style = space
                            indent_size = 4
                        '';
                    };
                };
                formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "yaml-formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/yaml-indent;
                        repoContent.editorConfig = ''
                            root = true

                            [*]
                            indent_style = space
                            indent_size = 4

                            [*.yaml]
                            indent_size = 2
                        '';
                    };
                };
                formatting-ymlSectionIgnored-appliesYamlPolicyToBothExtensions = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "yaml-formatting-ymlSectionIgnored-appliesYamlPolicyToBothExtensions";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/yaml-per-file;
                        repoContent.editorConfig = ''
                            root = true

                            [*.yaml]
                            indent_style = space
                            indent_size = 4

                            [*.yml]
                            indent_style = space
                            indent_size = 2
                        '';
                    };
                };
                formatting-width40-wrapsLongLine = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "yaml-formatting-width40-wrapsLongLine";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/yaml-width;
                        repoContent.editorConfig = ''
                            root = true

                            [*.yaml]
                            max_line_length = 40
                        '';
                    };
                };
                formatting-disabledLineLength-preservesLineWithinDefaultWidth = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "yaml-formatting-disabledLineLength-preservesLineWithinDefaultWidth";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/yaml-width;
                        repoContent.editorConfig = ''
                            root = true

                            [*.yaml]
                            max_line_length = off
                        '';
                    };
                };
            };
        };
    };
}
