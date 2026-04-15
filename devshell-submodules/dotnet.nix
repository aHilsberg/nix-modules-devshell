{
  lib, config, pkgs, ...
}: {
  options.dotnet = {
    enable = lib.mkEnableOption ".NET tooling for this shell";
  }

  config = lib.mkIf config.dotnet.enable {
    packages = [
      pkgs.dotnet-sdk
    ];

    env = [
      {
        name = "DOTNET_CLI_TELEMETRY_OPTOUT";
        value = "1";
      }
    ];
  };
}
