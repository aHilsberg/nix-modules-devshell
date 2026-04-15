{
  lib,
  config,
  pkgs,
  customPackages,
  ...
}: {
  options.dotnet = {
    enable = lib.mkEnableOption ".NET tooling for this shell";

    sdk = lib.mkOption {
      type = lib.types.package;
      default = pkgs.dotnetCorePackages.sdk_10_0;
      example = lib.literalExpression ''
        pkgs.dotnetCorePackages.combinePackages [
          pkgs.dotnetCorePackages.sdk_8_0
          pkgs.dotnetCorePackages.sdk_10_0
        ]
      '';
      description = ''
        The .NET SDK package to use.
        Can be a single SDK or multiple SDKs combined using combinePackages.
      '';
    };

    testing.snapshots = lib.mkEnableOption "snapshot testing support (adds Verify.Terminal tool)";
  };

  config = lib.mkIf config.dotnet.enable {
    packages =
      [
        config.dotnet.sdk
        customPackages.reportgenerator
        customPackages.jetbrains-globaltools
      ]
      ++ lib.optionals config.dotnet.testing.snapshots [
        customPackages.verify-terminal
      ];

    env = [
      # root folder of a .NET installation that tooling or app launch can use
      {
        name = "DOTNET_ROOT";
        value = "${config.dotnet.sdk}/share/dotnet";
      }
      # workload packs, manifests, local tool installation location
      {
        name = "DOTNET_CLI_HOME";
        eval = "$PRJ_ROOT/.dev/dotnet/home";
      }
      # global-packages folder location
      {
        name = "NUGET_PACKAGES";
        eval = "$PRJ_ROOT/.dev/dotnet/nuget/packages";
      }
      {
        name = "NUGET_HTTP_CACHE_PATH";
        eval = "$PRJ_ROOT/.dev/dotnet/nuget/http-cache";
      }
      {
        name = "NUGET_PLUGINS_CACHE_PATH";
        eval = "$PRJ_ROOT/.dev/dotnet/nuget/plugins-cache";
      }
    ];

    formatting.treefmt = {
      settings.formatter = {
        "jb" = {
          command = lib.getExe customPackages.jetbrains-globaltools;
          options = [
            "cleanupcode"
          ];
          includes = [
            "*.cs"
            "*.csproj"
            "Directory.Packages.props"
          ];
          excludes = ["legacy/**"];
        };
      };
    };
  };
}
