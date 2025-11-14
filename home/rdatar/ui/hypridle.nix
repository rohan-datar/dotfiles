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
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "qs -c noctalia-shell ipc call lockScreen lock";
          before_sleep_cmd = "qs -c noctalia-shell ipc call lockScreen lock";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = "300";
            on-timeout = "brightnessctl -s set 10";
            on-resume = "brightnessctl -r";
          }

          {
            timeout = "330";
            on-timeout = "qs -c noctalia-shell ipc call lockScreen lock";
          }

          {
            timeout = "350";
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }

          {
            timeout = "1800";
            on-timeout = "hyprctl dispatch exit";
          }
        ];
      };
    };
  };
}
