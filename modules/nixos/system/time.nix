{ config, lib, ... }:
let
  inherit (lib) mkAfter;
in
{
  services.timesyncd.enable = false;
  services.chrony.enable = true;
  systemd.tmpfiles.rules = mkAfter [
    "z ${config.services.chrony.directory}/chrony.keys 0640 root chrony - -"
  ];
}
