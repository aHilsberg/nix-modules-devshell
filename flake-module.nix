localFlake @ {
  import-tree,
  projectLib,
}: {
  lib,
  flake-parts-lib,
  ...
}: {
  imports = [
    (import-tree ./modules)
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    config,
    pkgs,
    system,
    ...
  }: {
    options.devshells = lib.mkOption {
      description = ''
        Opinionated devshell definitions.

        Each attribute defines one devshell and also produces a matching
        devShells entry.
      '';

      type = lib.types.lazyAttrsOf (
        lib.types.submoduleWith {
          modules = [
            (import-tree ./devshell-submodules)
          ];

          specialArgs = {
            inherit pkgs system projectLib;
          };
        }
      );

      default = {};
    };

    config.devShells =
      lib.mapAttrs (_name: shellCfg: shellCfg.build.shell) config.devshells;
  });
}
