{
  config,
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    firefox
    # ghostty
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
    lazygit
    neovim
    ripgrep
    tmux
    wget
    zoxide
    zsh
    pstree
    starship
    nix-index
    obsidian
    discord
    zig
    tree-sitter
    aoc-cli
    inputs.agenix.packages.${system}.default
    lldb
    btop
    bat
    man-pages
    man-pages-posix
    pkl
    direnv
    pandoc
    wireshark
    comma
    nh
    any-nix-shell
  ];

  fonts.packages = [
    pkgs.maple-mono.NF
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.meslo-lg
    pkgs.nerd-fonts.hack
    pkgs.font-awesome
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-compact
    inputs.apple-fonts.packages.${pkgs.system}.sf-compact-nerd
    inputs.apple-fonts.packages.${pkgs.system}.ny
    inputs.apple-fonts.packages.${pkgs.system}.ny-nerd
  ];

  documentation = {
    enable = true;
    man.enable = true;
    info.enable = true;
  };
}
