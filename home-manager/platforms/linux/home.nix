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
    gnomeExtensions.user-themes
    magnetic-catppuccin-gtk
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-GTK";
      package = pkgs.magnetic-catppuccin-gtk;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  home.sessionVariables.GTK_THEME = "Catppuccin-GTK";

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = ["user-theme@gnome-shell-extensions.gcampax.github.com"];
    };
    "org/gnome/shell/extensions/user-theme" = {
      name = "Catppuccin-GTK";
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
