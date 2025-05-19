{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../common
    ./hypr
    ./app-themes.nix
  ];

  # home.pointerCursor = {
  #   package = pkgs.adwaita-icon-theme;
  #   x11.enable = true;
  #   name = "Adwaita";
  #   size = 38;
  # };

  catppuccin.cursors = {
    enable = true;
    flavor = "mocha";
    accent = "sky";
  };

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
    magnetic-catppuccin-gtk
    ghostty
  ];

  programs.fzf.enable = true;

  programs.kitty = {
    enable = true;
    font = {
      name = "Maple Mono NF";
      size = 16;
    };
    settings = {
      background_opacity = 0.85;
      background_blur = 16;
    };
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
