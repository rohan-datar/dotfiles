{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./tmux.nix
    ./lazygit.nix
    ./zsh.nix
    ./starship.nix
    ./ssh.nix
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".config/ghostty" = {
      source = ./ghostty;
    };
  };

  programs = {
    kitty = {
      enable = true;
      font = {
        name = "Maple Mono NF";
        size = 16;
      };
      settings = {
        background_opacity = 0.85;
        background_blur = 16;
      };
    };
    nix-index = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/rdatar/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    PATH = "$HOME/go/bin/:$PATH";
    TERMINAL = "kitty";
    BROWSER = "zen";
  };

  home.shellAliases = {
    vim = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
