{
  pkgs,
  inputs,
  ...
}:
{
  # shared with all systems
  olympus.packages = with pkgs; [
    python3
    uutils-coreutils-noprefix
    fd
    git
    tmux
    zoxide
    inputs.agenix.packages.${system}.default
    btop
    bat
    comma
    any-nix-shell
  ];
}
