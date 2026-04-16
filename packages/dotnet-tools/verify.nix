{lib, ...}: {
    perSystem = {pkgs, ...}: {
        packages.verify-terminal = pkgs.buildDotnetModule rec {
            pname = "dotnet-verify";
            version = "0.7.0";

            src = pkgs.fetchFromGitHub {
                owner = "VerifyTests";
                repo = "Verify.Terminal";
                rev = "0.7.0";
                hash = "sha256-64rW1diVGJDALraCoeNN0q11A4UcSPUvPJbalp88ciA=";
            };

            projectFile = "src/Verify.Terminal/Verify.Terminal.csproj";
            # generate this with: build .#dotnet-verify.fetch-deps && ./result
            nugetDeps = ./verify.deps.json;

            dotnet-sdk = pkgs.dotnetCorePackages.sdk_10_0;
            dotnet-runtime = pkgs.dotnetCorePackages.runtime_10_0;

            executables = ["Verify.Terminal"];

            dotnetBuildFlags = [
                "-p:MinVerSkip=true"
                "-p:Version=${version}"
            ];

            dotnetInstallFlags = [
                "-p:MinVerSkip=true"
                "-p:Version=${version}"
                "-p:PackageVersion=${version}"
                "-f"
                "net10.0"
            ];

            postFixup = ''
                # Rename (instead of linking) to lowercase to avoid case-sensitivity issues on macOS
                mv $out/bin/Verify.Terminal $out/bin/dotnet-verify
            '';

            meta = with lib; {
                description = "CLI for managing Verify snapshots";
                homepage = "https://github.com/VerifyTests/Verify.Terminal";
                changelog = "https://github.com/VerifyTests/Verify.Terminal/releases/tag/${version}";
                license = licenses.mit;
                platforms = platforms.linux ++ platforms.darwin;
                mainProgram = "dotnet-verify";
            };
        };
    };
}
