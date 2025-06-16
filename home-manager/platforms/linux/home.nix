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

  home.packages = with pkgs; [
    blueman
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    pavucontrol
    brightnessctl
    playerctl
    networkmanager_dmenu
    networkmanagerapplet
    wlogout
    gnomeExtensions.user-themes
    ghostty
  ];

  programs.fzf.enable = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
