# this file is used to enable or disable shell integrations based on the shell itself
{ config, ... }:
{
  home.shell = {
    # disable the global enable
    enableShellIntegration = false;

    enableBashIntegration = config.programs.bash.enable;
    enableIonIntegration = config.programs.ion.enable;
    enableNushellIntegration = config.programs.nushell.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
}
