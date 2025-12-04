{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    services.swayidle =
      let
        # lock command
        lock = "noctalia-shell ipc call lockScreen lock";
        display = status: "${pkgs.niri}/bin/niri msg action power-${status}-monitors";
      in
      {
        enable = true;
        timeouts = [
          {
            timeout = 300;
            command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
            resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
          {
            timeout = 330;
            command = lock;
          }
          {
            timeout = 350;
            command = display "off";
            resumeCommand = display "on";
          }
          {
            timeout = 1800;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];

        events = {

          "before-sleep" = (display "off") + "; " + lock;

          "after-resume" = display "on";

          "lock" = (display "off") + "; " + lock;

          "unlock" = display "on";

        };
      };
  };
}
