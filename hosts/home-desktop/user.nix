{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rdatar = {
    isNormalUser = true;
    description = "Rohan Datar";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "rdatar";

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
    };
  };
}
