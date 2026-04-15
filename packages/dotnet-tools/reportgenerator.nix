{lib, ...}: {
  perSystem = {pkgs, ...}: {
    packages.reportgenerator = pkgs.buildDotnetModule rec {
      pname = "dotnet-reportgenerator-globaltool";
      version = "5.5.4";

      src = pkgs.fetchFromGitHub {
        owner = "danielpalme";
        repo = "ReportGenerator";
        rev = "v${version}";
        hash = "sha256-MRXLIm1q60ds+ZtF1oPt3UNhAXPvPlwIu4wse+Fa25g=";
      };

      projectFile = "src/ReportGenerator.DotnetGlobalTool/ReportGenerator.DotnetGlobalTool.csproj";
      # generate this with: nix build .#reportgenerator.fetch-deps && ./result
      nugetDeps = ./reportgenerator.deps.json;

      dotnet-sdk = pkgs.dotnetCorePackages.sdk_10_0;
      dotnet-runtime = pkgs.dotnetCorePackages.runtime_10_0;

      executables = ["ReportGenerator"];

      dotnetBuildFlags = [
        "-p:Version=${version}"
      ];

      dotnetInstallFlags = [
        "-p:Version=${version}"
        "-p:PackageVersion=${version}"
        "-f"
        "net10.0"
      ];

      postFixup = ''
        # Rename (instead of linking) to lowercase to avoid case-sensitivity issues on macOS
        mv $out/bin/ReportGenerator $out/bin/reportgenerator
      '';

      meta = with lib; {
        description = "Converts coverage reports into human readable reports in various formats";
        homepage = "https://github.com/danielpalme/ReportGenerator";
        changelog = "https://github.com/danielpalme/ReportGenerator/releases/tag/v${version}";
        license = licenses.asl20;
        platforms = platforms.linux ++ platforms.darwin;
        mainProgram = "reportgenerator";
      };
    };
  };
}
