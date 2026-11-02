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

    # Mirrored (RAID1) 1 TB SAS HDDs behind the P440ar (HBA mode) for bulk k3s PVC storage.
    sas1 = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-MB1000GCEEK_WCAW31VHVAE2";
      content = {
        type = "gpt";
        partitions.k3s-storage-1 = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "ganymede-k3s-storage"
              "-m"
              "raid1"
              "-d"
              "raid1"
              "/dev/disk/by-partlabel/disk-sas2-k3s-storage-2"
            ];
            mountpoint = "/var/lib/rancher/k3s/storage";
            mountOptions = [
              "nofail"
              "noatime"
              "compress=zstd"
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
        partitions.k3s-storage-2 = {
          size = "100%";
        };
      };
    };
  };
}
