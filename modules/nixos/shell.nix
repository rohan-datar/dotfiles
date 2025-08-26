{ pkgs, ... }:
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
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };
}
