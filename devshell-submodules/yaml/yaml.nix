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
            settings.formatter = let
                denoFmtConfigFromEditorConfig = pkgs.writeShellApplication {
                    name = "deno-fmt-config-from-editorconfig";

                    runtimeInputs = [
                        pkgs.nushell
                        pkgs.deno
                        pkgs.editorconfig-core-c
                        pkgs.git
                    ];

                    text = ''
                        set -euo pipefail

                        for file in "$@"; do
                          config="$(mktemp --suffix .deno.json)"
                          trap 'rm -f "$config"' EXIT

                          FILE="$file" nu --no-config-file ${./deno-fmt-config-from-editorconfig.nu} > "$config"

                          deno fmt --config "$config" "$file"

                          rm -f "$config"
                          trap - EXIT
                        done
                    '';
                };
            in {
                "deno" = {
                    command = lib.getExe denoFmtConfigFromEditorConfig;
                    includes = [
                        "*.yaml"
                        "*.yml"
                    ];
                };
            };
        };
    };
}
