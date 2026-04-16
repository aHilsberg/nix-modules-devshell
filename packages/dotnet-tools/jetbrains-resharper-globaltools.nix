{lib, ...}: {
    perSystem = {pkgs, ...}: {
        packages.jetbrains-globaltools = pkgs.buildDotnetGlobalTool {
            pname = "jb";
            version = "2025.3.3";

            nugetName = "JetBrains.ReSharper.GlobalTools";
            nugetHash = "sha256-0UnVAYwDl6sOV08SgQUuJu5wypf4uJvBnoPwYWX6G30=";

            dotnet-sdk = pkgs.dotnetCorePackages.sdk_8_0;
            dotnet-runtime = pkgs.dotnetCorePackages.sdk_8_0;

            postFixup = ''
                # Rename (instead of linking) to lowercase to avoid case-sensitivity issues on macOS
                mv $out/bin/jb $out/bin/dotnet-jb
            '';

            meta = with lib; {
                description = "CLI for C# automatic code quality";
                homepage = "https://www.jetbrains.com/help/resharper/ReSharper_Command_Line_Tools.html";
                platforms = platforms.linux ++ platforms.darwin;
                mainProgram = "dotnet-jb";
            };
        };
    };
}
