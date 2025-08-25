{ pkgs, ... }:
{
  olympus.packages = {
    inherit (pkgs)
      blueman
      hyprshot
      hyprlock
      hypridle
      pavucontrol
      brightnessctl
      fuzzel
      ;
  };

}
