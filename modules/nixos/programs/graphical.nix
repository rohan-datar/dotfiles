{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkIf mkOption types;
in {
  options.olympus.aspects.graphical.windowManager = mkOption {
    type = types.nullOr (
      types.enum [
        "hyprland"
        # add more here
      ]
    );
    default = null;
  };

  config = mkIf config.olympus.aspects.graphical.enable {
    programs = {
      # we need dconf to interact with gtk
      dconf.enable = true;

      # gnome's keyring manager
      seahorse.enable = true;
    };
  };
}
