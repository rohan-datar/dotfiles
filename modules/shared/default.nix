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

  nix.settings = {
    warn-dirty = false;
    experimental-features = ["nix-command" "flakes"];
  };
}
