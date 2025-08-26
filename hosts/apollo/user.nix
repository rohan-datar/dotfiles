{
  home-manager.users.rohandatar = {
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

    olympus.programs.defaults = {
      shell = "fish";
    };
  };
}
