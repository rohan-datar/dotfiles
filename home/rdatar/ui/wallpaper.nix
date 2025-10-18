{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    services.wpaperd = {
      enable = true;
      settings = {
        default = {
          path = "~/.local/share/backgrounds/";
          duration = "30m";
        };
      };
    };
  };
}
