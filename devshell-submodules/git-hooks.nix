{
    customPkgs,
    lib,
    perSysCfg,
    ...
}: {
    commands = lib.mkIf perSysCfg.git-hooks.enable [
        {
            name = "run-git-hooks";
            package = customPkgs.run-git-hooks;
            category = "development";
            help = "Run the configured Git hooks.";
        }
    ];

    startup = lib.mkIf perSysCfg.git-hooks.enable {
        git-hooks = {
            text = perSysCfg.pre-commit.installationScript;
        };
    };
}
