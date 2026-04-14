{
  description = "Collection of nix modules for ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {
        self,
        config,
        withSystem,
        flake-parts-lib,
        lib,
        ...
      }: let
        inherit (flake-parts-lib) importApply;
        flakeModule = importApply ./flake-module.nix {
          inherit inputs;
        };
      in {
        imports = [
          inputs.flake-parts.flakeModules.flakeModules
          ./pkgs.nix
          flakeModule # use own devshell modules - https://flake.parts/dogfood-a-reusable-module
        ];
        flake.flakeModules.default = flakeModule;

        _module.args.mkDevShellDefault = lib.mkOverride 60;

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        perSystem = {
          devshells.default = {
            env = [
              {
                name = "Test2";
                value = "MODULES WORK2";
              }
            ];
          };
        };
      }
    );
}
