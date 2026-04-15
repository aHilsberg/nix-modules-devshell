{
  lib,
  config,
  pkgs,
  ...
}: {
  options.markdown = {
    enable = lib.mkEnableOption "Markdown formatting for this shell";
  };

  config = lib.mkIf config.markdown.enable {
    formatting.treefmt = {
      programs.prettier = {
        enable = true;
        includes = [
          "*.md"
          "*.markdown"
        ];

        settings = {
          editorconfig = true;
        };
      };
    };
  };
}
