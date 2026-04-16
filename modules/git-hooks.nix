{
  flake-parts-lib,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.git-hooks-nix.flakeModule
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    config,
    pkgs,
    ...
  }: {
    options.git-hooks = {
      enable = lib.mkEnableOption "Git hooks for this project";

      runStages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["manual" "pre-commit" "pre-push"];
        description = ''
          List of git hook stages to run when executing the manual `run-git-hooks` command.
          Common stages include: "pre-commit", "pre-push"
        '';
        example = ["pre-commit" "pre-push"];
      };
    };

    config = {
      # see https://flake.parts/options/git-hooks-nix.html#options
      pre-commit = lib.mkMerge [
        {
          check.enable = false; # no running hooks as a nix flake check, since hooks run nix flake check
        }

        (lib.mkIf config.git-hooks.enable (lib.mkMerge [
          {
            settings.hooks = {
              flake-check = {
                enable = true;
                entry = "${lib.getExe pkgs.nix} --extra-experimental-features 'nix-command flakes' flake check";
                pass_filenames = false;
                stages = ["pre-push"];
              };
            };
          }
        ]))
      ];

      packages.run-git-hooks =
        lib.mkIf config.git-hooks.enable
        (let
          preCommitConfig = config.pre-commit.settings;
          inherit (preCommitConfig) package configFile;
          stageCommands =
            lib.concatMapStringsSep "\n" (stage: ''
              ${pkgs.lib.getExe package} run --all-files --config ${configFile} --hook-stage ${stage} || exit 1
            '')
            config.git-hooks.runStages;
          script = ''
            ${stageCommands}
          '';
        in
          pkgs.writeShellScriptBin "run-git-hooks" script);

      gitignore.entries =
        lib.mkIf config.git-hooks.enable
        [".pre-commit-config.yaml"];
    };
  });
}
