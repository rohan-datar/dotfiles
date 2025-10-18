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
    services.dunst.enable = true;
  };
}
