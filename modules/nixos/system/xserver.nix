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
  config = mkIf config.olympus.aspects.graphical.enable {
    services.xserver = {
      enable = true;
      desktopManager.xterm.enable = false;

      excludePackages = [ pkgs.xterm ];
    };
  };
}
