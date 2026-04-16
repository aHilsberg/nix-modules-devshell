{
  customPkgs,
  lib,
  perSysCfg,
  ...
}: {
  packages = lib.mkIf perSysCfg.git-hooks.enable [
    customPkgs.run-git-hooks
  ];

  startup = lib.mkIf perSysCfg.git-hooks.enable {
    git-hooks = {
      text = perSysCfg.pre-commit.installationScript;
    };
  };
}
