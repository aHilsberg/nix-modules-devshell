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
            pkgs.runCommandLocal "editorconfig-python" {
                nativeBuildInputs = [pkgs.editorconfig-core-c];
            } ''
                ${lib.getExe' pkgs.editorconfig-core-c "editorconfig"} ${lib.escapeShellArg (toString (self + "/python.py"))} > "$out"
            ''
        else pkgs.writeText "editorconfig-python" "";

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
    positiveInteger = maximum: value: let
        # Bound conversion before parsing, including arbitrarily large EditorConfig values.
        match =
            if value == null
            then null
            else builtins.match "0*([1-9][0-9]{0,2})" value;
        number =
            if match == null
            then null
            else builtins.fromJSON (builtins.head match);
    in
        if number != null && number <= maximum
        then number
        else null;

    indentStyle = getValue "indent_style";
    indentSize = getValue "indent_size";
    # maximums come from the ruff implementation (version: 0.15.9)
    indentWidth = positiveInteger 255 (
        if indentSize == "tab"
        then getValue "tab_width"
        else indentSize
    );
    lineLength = positiveInteger 320 (getValue "max_line_length");
    lineEnding = getValue "end_of_line";

    # Override only mapped settings, retaining project Ruff configuration and lint rules.
    ruffSettings =
        lib.optionalAttrs (builtins.elem indentStyle ["space" "tab"]) {
            "format.indent-style" = indentStyle;
        }
        // lib.optionalAttrs (indentWidth != null) {"indent-width" = indentWidth;}
        // lib.optionalAttrs (lineLength != null) {"line-length" = lineLength;}
        // lib.optionalAttrs (builtins.elem lineEnding ["lf" "crlf"]) {
            "format.line-ending" =
                if lineEnding == "crlf"
                then "cr-lf"
                else lineEnding;
        };
    ruffArguments = lib.concatLists (lib.mapAttrsToList (name: value: [
        "--config"
        "${name} = ${builtins.toJSON value}"
    ])
    ruffSettings);
    ruffWrapper = pkgs.writeShellScriptBin "ruff" ''
        exec ${lib.getExe pkgs.ruff} ${lib.escapeShellArgs ruffArguments} "$@"
    '';
in {
    options.python = {
        enable = lib.mkEnableOption "Python tooling for this shell";

        package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.python3;
            defaultText = lib.literalExpression "pkgs.python3";
            example = lib.literalExpression "pkgs.python314";
            description = "The Python interpreter package to use.";
        };

        extraPackages = lib.mkOption {
            type = lib.types.functionTo (lib.types.listOf lib.types.package);
            default = _: [];
            defaultText = lib.literalExpression "_: []";
            example = lib.literalExpression "ps: [ ps.requests ]";
            description = ''
                Additional Nix-packaged Python dependencies, selected from the
                configured interpreter's package set and added with withPackages.
            '';
        };
    };

    config = lib.mkIf config.python.enable {
        packages = [
            (config.python.package.withPackages config.python.extraPackages)
        ];

        formatting.treefmt.programs = {
            ruff-check = {
                enable = true;
                package = ruffWrapper;
                priority = 1;
            };
            ruff-format = {
                enable = true;
                package = ruffWrapper;
                priority = 2;
            };
        };
    };
}
