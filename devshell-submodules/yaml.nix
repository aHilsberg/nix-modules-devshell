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
            };
        };
    };
}
