{ config, ... }:
{
  imports = [ ./cursor.nix ];

  stylix = {
    inherit (config.olympus.aspects.graphical) enable;
  };
}
