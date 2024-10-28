{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    alejandra
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
  ];

  programs.neovim = {
    defaultEditor = true;
    vimAlias = true;
  };
}
