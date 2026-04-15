{
  lib,
  config,
  ...
}: {
  options.nix = {
    enable = lib.mkEnableOption "Nix formatting for this shell";
  };

  config = lib.mkIf config.nix.enable {
    formatting.treefmt = {
      programs = {
        # removes unused / unreachable code
        deadnix = {
          enable = true;
          priority = 1;
        };

        # formater (!should be after all others, to have consitent output)
        alejandra = {
          enable = true;
          priority = 2;
        };
      };
    };
  };
}
