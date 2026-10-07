{
    description = "Opinionated devshell flake-parts module";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
        import-tree.url = "github:vic/import-tree";

        devshell = {
            url = "github:numtide/devshell";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        treefmt-nix.url = "github:numtide/treefmt-nix";
        git-hooks-nix.url = "github:cachix/git-hooks.nix";
        files = {
            url = "github:mightyiam/files";
            flake = false;
        };

        testing = {
            url = "github:USE-MY-ENERGY-GmbH/nix-modules-testing";
            inputs.flake-parts.follows = "flake-parts";
        };
    };

    outputs = inputs @ {flake-parts, ...}:
        flake-parts.lib.mkFlake {inherit inputs;} (
            {
                flake-parts-lib,
                config,
                projectLib,
                withSystem,
                ...
            }: let
                inherit (flake-parts-lib) importApply;
                devshellFlakeModule = importApply ./flake-module.nix {
                    localInputs = inputs;
                    inherit projectLib withSystem;
                };
            in {
                imports = [
                    inputs.flake-parts.flakeModules.modules
                    inputs.testing.flakeModule
                    ./lib.nix
                    ./pkgs.nix

                    ./documentation.nix
                    (inputs.import-tree ./packages)
                    (inputs.import-tree.filterNot
                    (path:
                        inputs.nixpkgs.lib.hasSuffix ".lib.nix" path
                        || inputs.nixpkgs.lib.hasSuffix ".no-auto-import.nix" path
                        || inputs.nixpkgs.lib.hasInfix "/fixtures/" path
                        || inputs.nixpkgs.lib.hasInfix "/data/" path
                        || inputs.nixpkgs.lib.hasInfix "/snapshots/" path)
                    ./tests)

                    devshellFlakeModule
                ];

                systems = [
                    "x86_64-linux"
                    "aarch64-linux"
                    "aarch64-darwin"
                ];

                flake.overlays = {
                    default = inputs.devshell.overlays.default;
                    nushell = _: prev: {
                        nushell =
                            inputs.testing.inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.nushell;
                    };
                };

                flake.flakeModule = config.flake.flakeModules.default;
                flake.flakeModules.default = devshellFlakeModule;

                perSystem = {pkgs, ...}: {
                    formatting = {
                        enable = true;
                        excludes = [
                            "tests/data/**"
                            "tests/fixtures/**"
                            "tests/snapshots/**"
                        ];
                    };
                    
                    gitignore = {
                        enable = true;
                        entries = [
                            ".data/"
                        ];
                    };
                    
                    git-hooks.enable = true;
                    pre-commit.settings.hooks.tests = {
                        enable = true;
                        entry = "${pkgs.nix}/bin/nix --extra-experimental-features 'nix-command flakes pipe-operators' run .#tests -- run";
                        pass_filenames = false;
                        always_run = true;
                        stages = ["pre-push"];
                    };

                    devshells.default = {
                        markdown.enable = true;
                        nix.enable = true;
                    };
                };
            }
        );
}
