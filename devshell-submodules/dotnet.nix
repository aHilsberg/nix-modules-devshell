{
    customPkgs,
    lib,
    config,
    pkgs,
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
                customPkgs.report-generator
                customPkgs.dotnet-outdated
                customPkgs.jetbrains-globaltools
            ]
            ++ lib.optionals config.dotnet.testing.snapshots [
                customPkgs.verify-terminal
            ];

        commands =
            [
                {
                    name = "dotnet outdated";
                    package = customPkgs.dotnet-outdated;
                    category = "development";
                    help = "Check nuget package for upgradable versions and run package upgrades via cli.";
                }
                {
                    name = "report-generator";
                    package = customPkgs.report-generator;
                    category = "development";
                    help = "Convert Test Output to HTML or other Test/Coverage Output Formats";
                }
            ]
            ++ lib.optionals config.dotnet.testing.snapshots [
                {
                    name = "dotnet verify";
                    package = customPkgs.verify-terminal;
                    category = "development";
                    help = "Cli for reviewing/accepting/rejecting snapshot test output";
                }
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

            {
                name = "DOTNET_SKIP_FIRST_TIME_EXPERIENCE";
                value = "1";
            }
        ];

        formatting.treefmt = {
            settings.formatter = {
                "jb" = {
                    command = lib.getExe customPkgs.jetbrains-globaltools;
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
