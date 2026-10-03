{
    lib,
    config,
    pkgs,
    self,
    ...
}: let
    editorconfigPath = self + "/.editorconfig";
    hasEditorconfig = builtins.pathExists editorconfigPath;

    editorconfigEvaluated =
        if hasEditorconfig
        then
            pkgs.runCommandLocal "editorconfig-yaml" {
                nativeBuildInputs = [pkgs.editorconfig-core-c];
            } ''
                ${lib.getExe' pkgs.editorconfig-core-c "editorconfig"} ${lib.escapeShellArg (toString (self + "/any.yaml"))} > "$out"
            ''
        else pkgs.writeText "editorconfig-yaml" "";

    lines = lib.splitString "\n" (builtins.readFile editorconfigEvaluated);
    parseKv = line: let
        match = builtins.match "[[:space:]]*([^=[:space:]]+)[[:space:]]*=[[:space:]]*(.*)" line;
    in
        if lib.strings.trim line == "" || match == null
        then null
        else {
            name = lib.strings.trim (builtins.elemAt match 0);
            value = lib.strings.trim (builtins.elemAt match 1);
        };
    editorconfig = builtins.listToAttrs (builtins.filter (entry: entry != null) (map parseKv lines));
    getValue = name: editorconfig.${name} or null;
    positiveInteger = value: let
        match =
            if value == null
            then null
            else builtins.match "0*([1-9][0-9]*)" value;
        parsed = builtins.tryEval (builtins.fromJSON (builtins.head match));
    in
        if match != null && parsed.success && builtins.isInt parsed.value && parsed.value > 0
        then parsed.value
        else null;

    indentStyle = getValue "indent_style";
    indentSize = getValue "indent_size";
    indentWidth = positiveInteger (
        if indentSize == "tab"
        then getValue "tab_width"
        else indentSize
    );
    lineWidth = positiveInteger (getValue "max_line_length");

    # One policy resolved for a root-level YAML path applies to both extensions.
    denoConfig = pkgs.writeText "deno-fmt.json" (builtins.toJSON {
        fmt =
            lib.optionalAttrs (builtins.elem indentStyle ["space" "tab"]) {
                useTabs = indentStyle == "tab";
            }
            // lib.optionalAttrs (indentWidth != null) {inherit indentWidth;}
            // lib.optionalAttrs (lineWidth != null) {inherit lineWidth;};
    });
in {
    options.yaml = {
        enable = lib.mkEnableOption "YAML formatting for this shell";
    };

    config = lib.mkIf config.yaml.enable {
        formatting.treefmt.settings.formatter."deno" = {
            command = lib.getExe pkgs.deno;
            options = [
                "fmt"
                "--config"
                (toString denoConfig)
            ];
            includes = [
                "*.yaml"
                "*.yml"
            ];
        };
    };
}
