{
  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "rdatar";

  # this is kinda weird but I don't want to do a bunch of work to share options between home-manager and nixos
  programs.hyprland.enable = true;

  home-manager.users.rdatar = {
    programs = {
      bat.enable = true;
      ghostty.enable = true;
      ssh.enable = true;
      fish.enable = true;
      fzf.enable = true;
      starship.enable = true;
      tmux.enable = true;
      zsh.enable = true;
      neovim.enable = true;
      firefox.enable = true;
      fuzzel.enable = true;
    };

    # olympus.programs.defaults = {
    #   shell = "fish";
    # };
  };
}
