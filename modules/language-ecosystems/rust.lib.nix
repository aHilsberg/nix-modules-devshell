{ ... }: {
    modules.devshell.rust =
        { self, ... }:
        {
            lib,
            config,
            pkgs,
            ...
        }:
        let
            editorconfigPath = self + "/.editorconfig";
            hasEditorconfig = builtins.pathExists editorconfigPath;

            editorconfigEvaluated =
                if hasEditorconfig then
                    pkgs.runCommandLocal "editorconfig-rust"
                        {
                            nativeBuildInputs = [ pkgs.editorconfig-core-c ];
                        }
                        ''
                            ${lib.getExe' pkgs.editorconfig-core-c "editorconfig"} ${
                                lib.escapeShellArg (toString (self + "/rust.rs"))
                            } > "$out"
                        ''
                else
                    pkgs.writeText "editorconfig-rust" "";

            lines = lib.splitString "\n" (builtins.readFile editorconfigEvaluated);
            parseKv =
                line:
                let
                    match = builtins.match "[[:space:]]*([^=[:space:]]+)[[:space:]]*=[[:space:]]*(.*)" line;
                in
                if lib.strings.trim line == "" || match == null then
                    null
                else
                    {
                        name = lib.strings.trim (builtins.elemAt match 0);
                        value = lib.strings.trim (builtins.elemAt match 1);
                    };
            editorconfig = builtins.listToAttrs (builtins.filter (entry: entry != null) (map parseKv lines));
            getValue = name: editorconfig.${name} or null;
            positiveInteger =
                value:
                let
                    match = if value == null then null else builtins.match "0*([1-9][0-9]*)" value;
                    parsed = builtins.tryEval (builtins.fromJSON (builtins.head match));
                in
                if match != null && parsed.success && builtins.isInt parsed.value && parsed.value > 0 then
                    parsed.value
                else
                    null;

            indentStyle = getValue "indent_style";
            indentSize = getValue "indent_size";
            indentWidth = positiveInteger (if indentSize == "tab" then getValue "tab_width" else indentSize);
            lineWidth = positiveInteger (getValue "max_line_length");
            lineEnding = getValue "end_of_line";

            # Override mapped settings without replacing the project's rustfmt.toml.
            rustfmtSettings =
                lib.optionalAttrs
                    (builtins.elem indentStyle [
                        "space"
                        "tab"
                    ])
                    {
                        hard_tabs = indentStyle == "tab";
                    }
                // lib.optionalAttrs (indentWidth != null) { tab_spaces = indentWidth; }
                // lib.optionalAttrs (lineWidth != null) { max_width = lineWidth; }
                //
                    lib.optionalAttrs
                        (builtins.elem lineEnding [
                            "lf"
                            "crlf"
                        ])
                        {
                            newline_style = if lineEnding == "lf" then "Unix" else "Windows";
                        };
            rustfmtArguments = lib.optionals (rustfmtSettings != { }) [
                "--config"
                (lib.concatStringsSep "," (
                    lib.mapAttrsToList (
                        name: value: "${name}=${if builtins.isBool value then lib.boolToString value else toString value}"
                    ) rustfmtSettings
                ))
            ];
            rustfmtWrapper = pkgs.writeShellScriptBin "rustfmt" ''
                exec ${lib.getExe pkgs.rustfmt} ${lib.escapeShellArgs rustfmtArguments} "$@"
            '';
        in
        {
            options.rust = {
                enable = lib.mkEnableOption "Rust tooling for this shell";
                testing.snapshots = lib.mkEnableOption "Insta snapshot testing support (adds cargo-insta)";
            };

            config = lib.mkIf config.rust.enable {
                packages = [
                    pkgs.rustc
                    pkgs.cargo
                    pkgs.clippy
                    pkgs.rustfmt
                    pkgs.cargo-expand
                ]
                ++ lib.optionals config.rust.testing.snapshots [ pkgs.cargo-insta ];

                formatting.treefmt.programs.rustfmt = {
                    enable = true;
                    package = rustfmtWrapper;
                };
            };
        };
}
