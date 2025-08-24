{
  lib,
  osConfig,
  ...
}: let
  cfg = osConfig.olympus.aspects;
in {
  olympus.aspects = {
    inherit
      (cfg)
      graphical
      server
      ;
  };
}
