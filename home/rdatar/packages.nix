{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
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
  };

}
