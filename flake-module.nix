{
    localInputs,
    projectLib,
    withSystem,
}:
{
    lib,
    flake-parts-lib,
    self,
    ...
}:
let
    # type: applyModules :: context -> { _: context -> moduleValue } -> [moduleValue]
    applyModules = context: registry: map (makeModule: makeModule context) (lib.attrValues registry);

    flakeContext = { inherit localInputs projectLib withSystem; };
in
{
    # import all flake level modules registered in the projectLib
    imports = applyModules flakeContext projectLib.modules.flake;

    options.perSystem = flake-parts-lib.mkPerSystemOption (
        {
            config,
            options,
            pkgs,
            system,
            ...
        }:
        let
            devshellContext = flakeContext // {
                inherit self;
                perSysCfg = config;
                perSysOptions = options;
                # withSystem belongs to the provider; config above belongs to the consumer.
                customPkgs = withSystem system ({ config, ... }: config.packages);
            };
        in
        {
            options.devshells = lib.mkOption {
                description = ''
                    Opinionated devshell definitions.

                    Each attribute defines one devshell and also produces a matching
                    devShells entry.
                '';

                type = lib.types.lazyAttrsOf (
                    lib.types.submoduleWith {
                        # import all devshell level modules registered in the projectLib
                        modules = applyModules devshellContext projectLib.modules.devshell;
                        specialArgs = { inherit pkgs system; };
                    }
                );

                default = { };
            };

            config.devShells = lib.mapAttrs (_name: shellCfg: shellCfg.build.shell) config.devshells;
        }
    );
}
