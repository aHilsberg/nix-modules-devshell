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
                devshells.default.json.enable = true;
            };
        in {
            json = {
                formatting-twoSpaceEditorConfig-formatsWithTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "json-formatting-twoSpaceEditorConfig-formatsWithTwoSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/json-indent;
                        repoContent.editorConfig = ''
                            root = true

                            [*.json]
                            indent_style = space
                            indent_size = 2
                        '';
                    };
                };
                formatting-fourSpaceEditorConfig-formatsWithFourSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "json-formatting-fourSpaceEditorConfig-formatsWithFourSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/json-indent;
                        repoContent.editorConfig = ''
                            root = true

                            [*.json]
                            indent_style = space
                            indent_size = 4
                        '';
                    };
                };
                formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "json-formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/json-indent;
                        repoContent.editorConfig = ''
                            root = true

                            [*]
                            indent_style = space
                            indent_size = 4

                            [*.json]
                            indent_size = 2
                        '';
                    };
                };
                formatting-width40-wrapsLongLine = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "json-formatting-width40-wrapsLongLine";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/json-width;
                        repoContent.editorConfig = ''
                            root = true

                            [*.json]
                            max_line_length = 40
                        '';
                    };
                };
                formatting-jsonc-retainsComments = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "json-formatting-jsonc-retainsComments";
                        snapshotPathRelativeTo = ./.;
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/json-comments;
                        repoContent.editorConfig = ''
                            root = true

                            [*.jsonc]
                            indent_size = 2
                        '';
                    };
                };
            };
        };
    };
}
