{pkgs}: {
  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on macos
  programs.fish.enable = true;
  programs.zsh.interactiveShellInit = ''
    # this overrides the default shell for interactive sessions to be fish
    # but keeps zsh in other scenarios to avoid compatibility issues
    # see https://wiki.nixos.org/wiki/Fish#section_Setting_fish_as_default_shell
    if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
    then
        exec fish -l
    fi
  '';
}
