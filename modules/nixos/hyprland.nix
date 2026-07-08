{
  flake.modules.nixos.hyprland =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config = lib.mkIf config.programs.hyprland.enable {
        programs.hyprland = {
          withUWSM = false;
          xwayland.enable = true;
        };

        programs.uwsm.enable = false;

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
    };
}
