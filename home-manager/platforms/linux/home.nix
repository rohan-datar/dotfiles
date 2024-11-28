{
  config,
  pkgs,
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

  catppuccin.pointerCursor = {
    enable = true;
    flavor = "mocha";
    accent = "dark";
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
  ];

  # gtk.catppuccin = {
  #   enable = true;
  #   flavor = "mocha";
  #   accent = "blue";
  #   size = "standard";
  #   gnomeShellTheme = true;
  #   icon = {
  #     enable = true;
  #     flavor = "mocha";
  #     accent = "blue";
  #   };
  # };

  # gtk = {
  #   enable = true;
  #   name = "Catppuccin-GTK";
  #
  # };
  gtk.enable = true;
  gtk.theme = {
    name = "Catppuccin-GTK";
    package = pkgs.magnetic-catppuccin-gtk.override {
      tweaks = [
        "black"
        "macos"
      ];
    };
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
