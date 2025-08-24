{
  flake,
  pkgs,
  inputs,
  ...
}:
{
  # shared with all systems
  olympus.packages = with pkgs; [
    uutils-coreutils-noprefix
    python3
    fd
    git
    tmux
    zoxide
    btop
    bat
    comma
    any-nix-shell
    inputs.agenix.packages.${system}.default
    flake.packages.${system}.nx
  ];
}
