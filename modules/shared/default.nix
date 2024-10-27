# common settings to all nix hosts
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./packages.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.warn-dirty = false;
  };
}
