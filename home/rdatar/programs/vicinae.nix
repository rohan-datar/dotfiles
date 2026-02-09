{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.olympus.aspects.graphical.enable {
    services.vicinae = {
      package = pkgs.vicinae;
      enable = true;
      systemd = {
        enable = true;
        autostart = true;
      };
    };
  };
}
