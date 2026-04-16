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
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (
      {
        flake-parts-lib,
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
          gitignore.enable = true;
          formatting.enable = true;
          git-hooks.enable = true;

          devshells.default = {
            packages = [pkgs.hello];

            env = [
              {
                name = "TEST_VAR";
                value = "WORKS";
              }
            ];

            dotnet = {
              enable = true;
              testing.snapshots = true;
              # sdk = pkgs.dotnetCorePackages.combinePackages [
              #   pkgs.dotnetCorePackages.sdk_8_0
              #   pkgs.dotnetCorePackages.sdk_10_0
              # ];
            };
            json.enable = true;
            markdown.enable = true;
            xml.enable = true;
            yaml.enable = true;
            nix.enable = true;
          };
        };
      }
    );
}
