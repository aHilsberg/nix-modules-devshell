{lib, ...}: {
    perSystem = {
        pkgs,
        config,
        ...
    }: {
        packages.jetbrains-resharper-cleanup = pkgs.writeShellApplication {
            name = "jetbrains-resharper-cleanup";
            text = ''
                exec ${lib.getExe config.packages.jetbrains-globaltools} cleanupcode "$@"
            '';

            meta = with lib; {
                description = "Wrapper for JetBrains ReSharper cleanupcode";
                homepage = "https://www.jetbrains.com/help/resharper/ReSharper_Command_Line_Tools.html";
                platforms = platforms.linux ++ platforms.darwin;
                mainProgram = "jetbrains-resharper-cleanup";
            };
        };
    };
}
