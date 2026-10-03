{
    lib,
    config,
    pkgs,
    customPkgs,
    self,
    ...
}: let
    editorconfigPath = self + "/.editorconfig";
    hasEditorconfig = builtins.pathExists editorconfigPath;

    editorconfigEvaluated =
        if hasEditorconfig
        then
            pkgs.runCommandLocal "editorconfig-flake-nix" {
                nativeBuildInputs = [pkgs.editorconfig-core-c];
            } ''
                ${lib.getExe' pkgs.editorconfig-core-c "editorconfig"} ${self + "/flake.nix"} > "$out"
            ''
        else pkgs.writeText "editorconfig-flake-nix" "";

    editorconfigText = builtins.readFile editorconfigEvaluated;

    lines = lib.splitString "\n" editorconfigText;
    parseKv = line: let
        m = builtins.match "[[:space:]]*([^=[:space:]]+)[[:space:]]*=[[:space:]]*(.*)" line;
    in
        if lib.strings.trim line == "" || m == null
        then null
        else {
            name = lib.strings.trim (builtins.elemAt m 0);
            value = lib.strings.trim (builtins.elemAt m 1);
        };
    editorconfig = builtins.listToAttrs (builtins.filter (entry: entry != null) (map parseKv lines));
    getValue = name: editorconfig.${name} or null;

    indentStyle = getValue "indent_style";
    indentSize = getValue "indent_size";
    indentation =
        if indentStyle == "tab"
        then "Tabs"
        else if indentSize == "4"
        then "FourSpaces"
        else "TwoSpaces";

    alejandraConfig = pkgs.writeText "alejandra.toml" ''
        indentation = "${indentation}"
    '';

    alejandraWrapper = pkgs.writeShellScriptBin "alejandra" ''
        exec ${lib.getExe pkgs.alejandra} --experimental-config ${alejandraConfig} "$@"
    '';
in {
    options.nix = {
        enable = lib.mkEnableOption "Nix formatting for this shell";
        formatter = lib.mkOption {
            type = lib.types.enum ["alejandra" "nixfmt"];
            default = "alejandra";
            description = "Nix formatter to use for this shell.";
        };
    };

    config = lib.mkIf config.nix.enable {
        packages = [customPkgs.nix-nvim];

        formatting.treefmt = {
            settings.formatter = {
                "deadnix" = {
                    command = lib.getExe pkgs.deadnix;
                    options = [
                        "--fail"
                    ];
                    includes = [
                        "*.nix"
                    ];
                    priority = 2;
                };
            };
            programs = {
                alejandra = {
                    enable = config.nix.formatter == "alejandra";
                    priority = 1;
                    package = alejandraWrapper;
                };

                nixfmt = {
                    enable = config.nix.formatter == "nixfmt";
                    priority = 1;
                    indent = builtins.fromJSON indentSize;
                };
            };
        };
    };
}
