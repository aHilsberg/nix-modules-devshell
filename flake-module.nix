localFlake @ {inputs}: {
  flake-parts-lib,
  lib,
  ...
}: {
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      system,
      ...
    }: {
      options.devshells = lib.mkOption {
        description = ''
          Configure devshells with flake-parts.

          Not to be confused with `devShells`, with a capital S. Yes, this
          is unfortunate.

          Each devshell will also configure an equivalent `devShells`.

          Used to define devshells. not to be confused with `devShells`
        '';

        type = lib.types.lazyAttrsOf (
          lib.types.submoduleWith {
            modules = [(inputs.import-tree ./modules)]; # import all nix files in ./modules tree as flake-parts modules
            specialArgs = {
              inherit pkgs system inputs;
            };
          }
        );
        default = {};
      };
      config.devShells = lib.mapAttrs (_name: devShellConfiguration: devShellConfiguration.build.shell) config.devshells;
    }
  );
}
