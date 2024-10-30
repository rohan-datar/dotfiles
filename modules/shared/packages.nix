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

  environment.shellAliases = {
    vim = "nvim";
    c = "clear";

    # ls aliases
    ls = "ls --color";
    lsa = "ls -lah";
    l = "ls -lah";
    ll = "ls -lh";
    la = "ls -lAh";
  };
}
