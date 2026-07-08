{ lib, ... }:
{
  flake.modules.nixos.time = {
    imports = [
      (
        { config, ... }:
        {
          systemd.tmpfiles.rules = lib.mkAfter [
            "z ${config.services.chrony.directory}/chrony.keys 0640 root chrony - -"
          ];
        }
      )
    ];

    config = {
      services.timesyncd.enable = false;
      services.chrony.enable = true;
    };
  };
}
