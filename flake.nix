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
        files.url = "github:mightyiam/files";

        testing = {
            url = "git+ssh://git@github.com/aHilsberg/nix-modules-testing.git";
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
                    nushell = final: prev: {
                        nushell =
                            inputs.testing.inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.nushell;
                    };
                };

                flake.flakeModule = config.flake.flakeModules.default;
                flake.flakeModules.default = devshellFlakeModule;

                perSystem = {...}: {
                    gitignore = {
                        enable = true;
                        entries = [
                            ".data/"
                        ];
                    };
                    formatting.excludes = [
                        "tests/data/**"
                        "tests/fixtures/**"
                        "tests/snapshots/**"
                    ];
                    formatting.enable = true;
                    git-hooks.enable = true;

                    devshells.default = {
                        markdown.enable = true;
                        nix.enable = true;
                    };
                };
            }
        );
}
