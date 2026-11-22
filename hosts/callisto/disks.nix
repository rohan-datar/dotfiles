{ lib, inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/disk/by-id/ata-PNY_250GB_SATA_SSD_PND09252385190100193";
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
