# common settings to all nix hosts
{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./packages.nix
    ./stylix.nix
  ];

  environment.shellAliases = {
    vim = "nvim";

    # ls aliases
    ls = "ls --color";
    lsa = "ls -lah";
    l = "ls -lah";
    ll = "ls -lh";
    la = "ls -lAh";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    warn-dirty = false;
    experimental-features = ["nix-command" "flakes"];
  };
}
