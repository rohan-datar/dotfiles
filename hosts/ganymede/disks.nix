{ lib, inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];
  disko.devices.disk = {
    main = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-Fanxiang_S101_128GB_26081394635000016";
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

    # Temporary local storage on the two 1 TB SAS HDDs behind the P440ar (HBA mode).
    sas1 = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-MB1000GCEEK_WCAW31VHVAE2";
      content = {
        type = "gpt";
        partitions.scratch1 = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/mnt/scratch1";
            mountOptions = [
              "nofail"
              "noatime"
            ];
          };
        };
      };
    };

    sas2 = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-MB1000GCEEK_WCAW36RKNDAF";
      content = {
        type = "gpt";
        partitions.scratch2 = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/mnt/scratch2";
            mountOptions = [
              "nofail"
              "noatime"
            ];
          };
        };
      };
    };
  };
}
