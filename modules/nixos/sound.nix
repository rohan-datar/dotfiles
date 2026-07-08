{ lib, ... }:
{
  flake.modules.nixos.sound = {
    imports = [
      (
        { config, ... }:
        {
          # able to change scheduling policies, e.g. to SCHED_RR
          security.rtkit.enable = lib.mkForce config.services.pipewire.enable;
        }
      )
    ];

    config = {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        jack.enable = true;
      };

      systemd.user.services = {
        pipewire.wantedBy = [ "default.target" ];
        pipewire-pulse.wantedBy = [ "default.target" ];
      };
    };
  };
}
