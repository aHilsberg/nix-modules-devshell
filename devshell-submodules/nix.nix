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
      pkgs.runCommand "editorconfig-flake-nix" {
        nativeBuildInputs = [pkgs.editorconfig-core-c];
      } ''
        ${lib.getExe' pkgs.editorconfig-core-c "editorconfig"} ${self + "/flake.nix"} > "$out"
      ''
    else pkgs.writeText "editorconfig-flake-nix" "";

  editorconfigText = builtins.readFile editorconfigEvaluated;

  lines = lib.splitString "\n" editorconfigText;
  trim = lib.strings.trim;

  parseKv = line: let
    m = builtins.match "[[:space:]]*([^=[:space:]]+)[[:space:]]*=[[:space:]]*(.*)" line;
  in
    if trim line == "" || m == null
    then null
    else {
      key = trim (builtins.elemAt m 0);
      value = trim (builtins.elemAt m 1);
    };

  entries = builtins.filter (x: x != null) (map parseKv lines);

  getValue = name: let
    matches = builtins.filter (x: x.key == name) entries;
  in
    if matches == []
    then null
    else (builtins.head matches).value;

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
  options.nix.enable = lib.mkEnableOption "Nix formatting for this shell";

  config = lib.mkIf config.nix.enable {
    packages = [customPkgs.nix-nvim];

    formatting.treefmt.programs = {
      deadnix = {
        enable = true;
        priority = 1;
      };

      alejandra = {
        enable = true;
        priority = 2;
        package = alejandraWrapper;
      };
    };
  };
}
