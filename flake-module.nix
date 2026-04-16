{
  localInputs,
  projectLib,
  withSystem,
}: {
  lib,
  flake-parts-lib,
  self,
  ...
}: {
  imports = [
    (
      # Wrapper that uses import-tree's .map to import each path and then apply args
      # All modules are expected to be nested functions: { localInputs, projectLib, ... }: { ... }: { ... }
      localInputs.import-tree.map (modulePath: (import modulePath) {inherit localInputs projectLib;})
      ./modules
    )
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    config,
    pkgs,
    system,
    ...
  }: {
    options = {
      devshell-submodule-extension = lib.mkOption {
        description = "Submodules specified by top level modules, to allow submodule to specify data used in toplevel modules";
        type = lib.types.listOf lib.types.deferredModule;
        default = [];
        internal = true;
      };

      devshells = lib.mkOption {
        description = ''
          Opinionated devshell definitions.

          Each attribute defines one devshell and also produces a matching
          devShells entry.
        '';

        type = lib.types.lazyAttrsOf (
          lib.types.submoduleWith {
            modules =
              [
                (localInputs.import-tree ./devshell-submodules)
              ]
              ++ config.devshell-submodule-extension;

            specialArgs = {
              inherit pkgs system projectLib self;
              perSysCfg = config;
              # make local config and packages accessible in submodules
              # see https://flake.parts/dogfood-a-reusable-module.html
              customPkgs = withSystem system (
                {config, ...}: config.packages
              );
            };
          }
        );

        default = {};
      };
    };

    config.devShells =
      lib.mapAttrs (_name: shellCfg: shellCfg.build.shell) config.devshells;
  });
}
