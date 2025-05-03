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

  catppuccin.cursors = {
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
    ghostty
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-GTK-Dark";
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
      name = "Catppuccin-GTK-Dark";
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

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
