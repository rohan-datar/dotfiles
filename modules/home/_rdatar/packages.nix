{
  pkgs,
  ...
}:
{
  config = {
    home.packages = [
      pkgs.blueman
      pkgs.hyprshot
      pkgs.hypridle
      pkgs.pavucontrol
      pkgs.brightnessctl
      pkgs.fuzzel
    ];
  };
}
