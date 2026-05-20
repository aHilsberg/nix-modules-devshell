{
    lib,
    config,
    ...
}: {
    options.yaml = {
        enable = lib.mkEnableOption "YAML formatting for this shell";
    };

    config = lib.mkIf config.yaml.enable {
        formatting.treefmt = {
            programs.yamlfmt = {
                enable = true;
                includes = [
                    "*.yaml"
                    "*.yml"
                ];

                settings = {
                    formatter = {
                        type = "basic";
                        retain_line_breaks = true;
                        retain_line_breaks_single = true;
                    };
                };
            };
        };
    };
}
