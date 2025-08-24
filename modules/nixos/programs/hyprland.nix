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
  config =
    mkIf
      (
        config.olympus.aspects.graphical.enable
        && config.olympus.aspects.graphical.windowManager == "hyprland"
      )
      {
        programs.hyprland = {
          enable = true;
          withUWSM = true;
          xwayland.enable = true;
        };

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
        };

        environment.sessionVariables = {
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_TYPE = "wayland";
          XDG_SESSION_DESKTOP = "Hyprland";
        };
      };
}
