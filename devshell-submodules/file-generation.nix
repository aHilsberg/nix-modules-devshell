{
  lib,
  customPackages,
  ...
}: {
  startup = {
    file-generation = {
      text = lib.getExe customPackages.generate-nix-managed-files;
    };
  };
}
