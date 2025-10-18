{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    programs = {
      # we need dconf to interact with gtk
      dconf.enable = true;

      # gnome's keyring manager
      seahorse.enable = true;
    };
  };
}
