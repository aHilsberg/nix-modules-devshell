{
  lib,
  config,
  pkgs,
  ...
}: {
  options.docker = {
    enable = lib.mkEnableOption "Docker formatting for this shell";
  };

  config = lib.mkIf config.docker.enable {
    formatting.treefmt = {
      programs.dockerfmt = {
        enable = true;
      };
    };
  };
}
