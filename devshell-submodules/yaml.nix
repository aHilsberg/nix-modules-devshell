{
  lib,
  config,
  pkgs,
  ...
}: {
  options.yaml = {
    enable = lib.mkEnableOption "YAML formatting for this shell";
  };

  config = lib.mkIf config.yaml.enable {
    formatting.treefmt = {
      programs.prettier = {
        enable = true;
        includes = [
          "*.yaml"
          "*.yml"
        ];

        settings = {
          editorconfig = true;
        };
      };
    };
  };
}
