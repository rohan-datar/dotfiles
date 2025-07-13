{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./tmux.nix
    ./zsh.nix
    ./fish.nix
    ./starship.nix
    ./ssh.nix
    ./git.nix
    ./neovim.nix
    # ./ghostty.nix
    ../../modules/shared/stylix.nix
    ../../modules/home/nix-build.nix
  ];

  nixpkgs.config.allowUnfree = true;

  stylix = {
    cursor = {
      package = pkgs.catppuccin-cursors.mochaBlue;
      name = "Catppuccin Mocha Blue";
      size = 45;
    };
    targets.fish.enable = false;
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".config/ghostty" = {
      source = ./ghostty;
    };
  };

  home.packages = with pkgs; [
    nix-output-monitor
    nvd
  ];

  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      tmux.enableShellIntegration = true;
    };

    nix-index = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    nix-index-database = {
      comma.enable = true;
    };

    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
    };

    bat.enable = true;

    kitty = {
      enable = true;
      font = {
        name = pkgs.lib.mkForce "Maple Mono NF";
        size = pkgs.lib.mkForce 14;
      };
    };
  };

  # this overrides the default shell for interactive sessions to be fish
  # but keeps bash in other scenarios to avoid compatibility issues
  # see https://wiki.nixos.org/wiki/Fish#section_Setting_fish_as_default_shell
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
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
    TERMINAL = "ghostty";
    BROWSER = "zen";
    MANPAGER = "nvim '+Man!'-";
    NIX_FLAKE_LOCATION = "$HOME/nix";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
