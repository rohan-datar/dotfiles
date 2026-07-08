{
  flake.modules.nixos.shell =
    {
      pkgs,
      self,
      ...
    }:
    {
      programs.fish.enable = true;

      # this overrides the default shell for interactive sessions to be fish
      # but keeps bash in other scenarios to avoid compatibility issues
      # see https://wiki.nixos.org/wiki/Fish#section_Setting_fish_as_default_shell
      programs.bash = {
        interactiveShellInit = ''
          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.fish}/bin/fish $LOGIN_OPTION
          fi
        '';
      };
    };

  flake.modules.darwin.shell = {
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
    programs.bash.enable = false;
  };
}
