{ lib, inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/disk/by-id/nvme-WD_PC_SN740_SDDPNQD-256G-2006_24015T800090";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
