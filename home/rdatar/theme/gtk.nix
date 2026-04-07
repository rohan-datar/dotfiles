{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (config.olympus.aspects.graphical.enable && pkgs.stdenv.hostPlatform.isLinux) {
    gtk = {
      enable = true;

      theme = {
        package = pkgs.magnetic-catppuccin-gtk;
        name = "Catppuccin-GTK-Dark";
      };

      gtk3.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };

      # Explicitly set to null to adopt new default behavior (GTK4 handles theming differently)
      gtk4.theme = null;
      gtk4.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
    };
    home.sessionVariables.GTK_THEME = "Catppuccin-GTK";
    dconf.settings = {
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      "org/gnome/shell/extensions/user-theme" = {
        name = "Catppuccin-GTK-Dark";
      };
    };
  };
}
