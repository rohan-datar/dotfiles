{
  config,
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    firefox
    # ghostty # currently marked as broken on darwin
    neofetch
    python3
    uutils-coreutils-noprefix
    fd
    git
    lazygit
    tmux
    wget
    zoxide
    obsidian
    discord
    tree-sitter
    aoc-cli
    inputs.agenix.packages.${system}.default
    btop
    bat
    direnv
    pandoc
    wireshark
    comma
    any-nix-shell
    floorp
    vscode
    wiregurard-ui
    bitwarden-desktop
  ];
}
