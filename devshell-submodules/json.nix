{
    lib,
    config,
    ...
}: {
    options.json = {
        enable = lib.mkEnableOption "JSON formatting for this shell";
    };

    config = lib.mkIf config.json.enable {
        formatting.treefmt = {
            programs.prettier = {
                enable = true;
                includes = [
                    "*.json"
                    "*.jsonc"
                ];

                settings = {
                    editorconfig = true;
                };
            };
        };
    };
}
