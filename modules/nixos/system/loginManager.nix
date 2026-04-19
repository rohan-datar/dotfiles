{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    services = {
      displayManager.sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;
        autoNumlock = true;
        settings.General.RememberLastSession = false;
        wayland = {
          enable = true;
          compositor = "kwin";
        };
      };
      displayManager.defaultSession = "niri";
    };
  };
}
