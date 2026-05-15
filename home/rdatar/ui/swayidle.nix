{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    services.swayidle =
      let
        noctaliaShell = "${inputs.noctalia.packages.${system}.default}/bin/noctalia-shell";

        # lock command
        lock = "${noctaliaShell} ipc call lockScreen lock";
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

          # Keep these focused on locking/waking only; forcing display-off here can
          # leave outputs stuck off across suspend/resume on some GPUs/monitors.
          "before-sleep" = lock;

          "after-resume" = display "on";

          "lock" = lock;

          "unlock" = display "on";

        };
      };
  };
}
