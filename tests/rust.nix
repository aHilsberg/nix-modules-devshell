{
    projectLib,
    ...
}:
{
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
                    inherit (testLib) asserts;

                    formatterModule.perSystem = {
                        formatting.enable = true;
                        devshells.default.rust.enable = true;
                    };
                in
                {
                    rust = {
                        formatting-twoSpaceIndent-formatsWithTwoSpaces = test.asserts {
                            tags = [ "formatting" ];
                            assertions = asserts.formatingAsExpected {
                                name = "rust-formatting-twoSpaceIndent-formatsWithTwoSpaces";
                                inherit formatterModule;
                                filetreeToFormat = ./fixtures/rust-indent;
                                snapshotPathRelativeTo = ./.;
                                repoContent.editorConfig = ''
                                    root = true

                                    [*.rs]
                                    indent_style = space
                                    indent_size = 2
                                '';
                            };
                        };
                        formatting-fourSpaceIndent-formatsWithFourSpaces = test.asserts {
                            tags = [ "formatting" ];
                            assertions = asserts.formatingAsExpected {
                                name = "rust-formatting-fourSpaceIndent-formatsWithFourSpaces";
                                inherit formatterModule;
                                filetreeToFormat = ./fixtures/rust-indent;
                                snapshotPathRelativeTo = ./.;
                                repoContent.editorConfig = ''
                                    root = true

                                    [*.rs]
                                    indent_style = space
                                    indent_size = 4
                                '';
                            };
                        };
                        formatting-tabIndent-formatsWithTabs = test.asserts {
                            tags = [ "formatting" ];
                            assertions = asserts.formatingAsExpected {
                                name = "rust-formatting-tabIndent-formatsWithTabs";
                                inherit formatterModule;
                                filetreeToFormat = ./fixtures/rust-indent;
                                snapshotPathRelativeTo = ./.;
                                repoContent.editorConfig = ''
                                    root = true

                                    [*.rs]
                                    indent_style = tab
                                    indent_size = tab
                                    tab_width = 4
                                '';
                            };
                        };
                        formatting-width40-wrapsLongLine = test.asserts {
                            tags = [ "formatting" ];
                            assertions = asserts.formatingAsExpected {
                                name = "rust-formatting-width40-wrapsLongLine";
                                inherit formatterModule;
                                filetreeToFormat = ./fixtures/rust-width;
                                snapshotPathRelativeTo = ./.;
                                repoContent.editorConfig = ''
                                    root = true

                                    [*.rs]
                                    max_line_length = 40
                                '';
                            };
                        };
                        formatting-noEditorConfig-usesRustfmtDefaults = test.asserts {
                            tags = [ "formatting" ];
                            assertions = asserts.formatingAsExpected {
                                name = "rust-formatting-noEditorConfig-usesRustfmtDefaults";
                                inherit formatterModule;
                                filetreeToFormat = ./fixtures/rust-indent;
                                snapshotPathRelativeTo = ./.;
                            };
                        };
                        formatting-editorConfigIndentationOverride-preservesRustfmtImportOrder = test.asserts {
                            tags = [ "formatting" ];
                            assertions = asserts.formatingAsExpected {
                                name = "rust-formatting-editorConfigIndentationOverride-preservesRustfmtImportOrder";
                                inherit formatterModule;
                                filetreeToFormat = ./fixtures/rust-config;
                                snapshotPathRelativeTo = ./.;
                                repoContent = {
                                    editorConfig = ''
                                        root = true

                                        [*.rs]
                                        indent_size = 2
                                    '';
                                    files."rustfmt.toml" = ''
                                        tab_spaces = 8
                                        reorder_imports = false
                                    '';
                                };
                            };
                        };
                        formatting-disabledLineLength-usesRustfmtDefaults = test.asserts {
                            tags = [ "formatting" ];
                            assertions = asserts.formatingAsExpected {
                                name = "rust-formatting-disabledLineLength-usesRustfmtDefaults";
                                inherit formatterModule;
                                filetreeToFormat = ./fixtures/rust-width;
                                snapshotPathRelativeTo = ./.;
                                repoContent.editorConfig = ''
                                    root = true

                                    [*.rs]
                                    max_line_length = off
                                    indent_size = unset
                                '';
                            };
                        };
                    };
                };
        };
}
