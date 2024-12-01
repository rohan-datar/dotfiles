{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    alejandra
    kitty
    neofetch
    bat
    python3
    coreutils
    codespell
    fd
    fzf
    git
    go
    jq
    lazygit
    neovim
    ripgrep
    shellcheck
    tmux
    wget
    yamllint
    yq
    zoxide
    zsh
    pstree
    starship
    nix-index
    obsidian
    discord
    tailscale
    sourcekit-lsp
    zig
    tree-sitter
  ];

  fonts.packages = with pkgs; [
    maple-mono-NF
    nerdfonts.fira-code
    nerdfonts.jetbrains-mono
    nerdfonts.meslo-lg
    nerdfonts.hack
    font-awesome
  ];
}
