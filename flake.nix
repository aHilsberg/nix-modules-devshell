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
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (
      {
        flake-parts-lib,
        self,
        withSystem,
        ...
      }: let
        inherit (flake-parts-lib) importApply;
        devshellFlakeModule = importApply ./flake-module.nix {
          inherit (inputs) import-tree;
          inherit projectLib withSystem;
        };
        projectLib = import ./lib.nix {inherit (nixpkgs) lib;};
      in {
        _module.args.projectLib = projectLib;
        imports = [
          ./pkgs.nix
          (inputs.import-tree ./packages)
          devshellFlakeModule
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        flake.flakeModules.default = devshellFlakeModule;

        perSystem = {pkgs, ...}: {
          formatting.enable = false;

          devshells.default = {
            packages = [pkgs.hello];

            env = [
              {
                name = "TEST_VAR";
                value = "MODULES WORK";
              }
            ];

            # git-hooks.enable = false; # TODO move to flake scope
            dotnet = {
              enable = true;
              sdk = pkgs.dotnetCorePackages.combinePackages [
                pkgs.dotnetCorePackages.sdk_8_0
                pkgs.dotnetCorePackages.sdk_10_0
              ];
            };
          };
        };
      }
    );
}
