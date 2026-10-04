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
            asserts = (projectLib.testing {inherit that should utils pkgs system;}).asserts;
            formatterModule.perSystem = {
                formatting.enable = true;
                devshells.default.nix = {
                    enable = true;
                    formatter = "alejandra";
                };
            };
            nixfmtFormatterModule = lib.recursiveUpdate formatterModule {
                perSystem.devshells.default.nix.formatter = "nixfmt";
            };
        in {
            nix = {
                formatting-twoSpaceEditorConfig-formatsWithTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "nix-formatting-twoSpaceEditorConfig-formatsWithTwoSpaces";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/data/nix;
                        snapshotPathRelativeTo = ./.;
                        repoContent.editorConfig = ''
                            root = true

                            [*.nix]
                            indent_style = space
                            indent_size = 2
                        '';
                    };
                };
                formatting-fourSpaceEditorConfig-formatsWithFourSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "nix-formatting-fourSpaceEditorConfig-formatsWithFourSpaces";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/data/nix;
                        snapshotPathRelativeTo = ./.;
                        repoContent.editorConfig = ''
                            root = true

                            [*.nix]
                            indent_style = space
                            indent_size = 4
                        '';
                    };
                };
                formatting-tabEditorConfig-formatsWithTabs = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "nix-formatting-tabEditorConfig-formatsWithTabs";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/data/nix;
                        snapshotPathRelativeTo = ./.;
                        repoContent.editorConfig = ''
                            root = true

                            [*.nix]
                            indent_style = tab
                            indent_size = 4
                        '';
                    };
                };
                formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "nix-formatting-editorConfigOverride-formatsWithFiletypeSpecificTwoSpaces";
                        inherit formatterModule;
                        filetreeToFormat = ./fixtures/data/nix;
                        snapshotPathRelativeTo = ./.;
                        repoContent.editorConfig = ''
                            root = true

                            [*]
                            indent_style = space
                            indent_size = 4

                            [*.nix]
                            indent_size = 2
                        '';
                    };
                };

                formatting-nixfmt-formatsWithFourSpaces = test.asserts {
                    tags = ["formatting"];
                    assertions = asserts.formatingAsExpected {
                        name = "nix-formatting-nixfmt-formatsWithFourSpaces";
                        formatterModule = nixfmtFormatterModule;
                        filetreeToFormat = ./fixtures/data/nix;
                        snapshotPathRelativeTo = ./.;
                        repoContent.editorConfig = ''
                            root = true

                            [*.nix]
                            indent_style = space
                            indent_size = 4
                        '';
                    };
                };
            };
        };
    };
}
