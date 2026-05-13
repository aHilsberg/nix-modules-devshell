{lib, ...}: {
    perSystem = {pkgs, ...}: {
        packages.dotnet-outdated = pkgs.buildDotnetModule rec {
            pname = "dotnet-outdated-tool";
            version = "4.7.1";

            src = pkgs.fetchFromGitHub {
                owner = "dotnet-outdated";
                repo = "dotnet-outdated";
                rev = "v${version}";
                hash = "sha256-0kuHEOqnM5kujQVRgIq20i7WBVYy/LNFz5N2FvZ2Iy4=";
            };

            projectFile = "src/DotNetOutdated/DotNetOutdated.csproj";
            # generate this with: nix build .#dotnet-outdated.fetch-deps && ./result packages/dotnet-tools/dotnet-outdated.deps.json
            nugetDeps = ./dotnet-outdated.deps.json;

            dotnet-sdk = pkgs.dotnetCorePackages.sdk_9_0;
            dotnet-runtime = pkgs.dotnetCorePackages.sdk_10_0;

            executables = ["dotnet-outdated"];

            dotnetBuildFlags = [
                "-f"
                "net9.0"
            ];

            dotnetInstallFlags = [
                "-f"
                "net9.0"
            ];

            meta = with lib; {
                description = "A .NET Core global tool to display and update outdated NuGet packages in a project";
                homepage = "https://github.com/dotnet-outdated/dotnet-outdated";
                changelog = "https://github.com/dotnet-outdated/dotnet-outdated/releases/tag/v${version}";
                license = licenses.mit;
                platforms = platforms.linux ++ platforms.darwin;
                mainProgram = "dotnet-outdated";
            };
        };
    };
}
