{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.olympus.aspects = {
    graphical.enable = mkEnableOption "Enable graphical environment aspects";
    server.enable = mkEnableOption "Enable server environment aspects";

  };
}
