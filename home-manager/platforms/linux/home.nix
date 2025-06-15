{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../common
    ./hypr
  ];

  # home.pointerCursor = {
  #   package = pkgs.adwaita-icon-theme;
  #   x11.enable = true;
  #   name = "Adwaita";
  #   size = 38;
  # };

  home.packages = with pkgs; [
    blueman
    waybar
    waybar-mpris
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    swaynotificationcenter
    pavucontrol
    brightnessctl
    playerctl
    networkmanager_dmenu
    networkmanagerapplet
    wlogout
    gnomeExtensions.user-themes
    ghostty
    ashell
  ];

  programs.fzf.enable = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
