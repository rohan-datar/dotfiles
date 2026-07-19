_: {
  flake.modules.nixos.nas-zfs =
    { lib, ... }:
    {
      boot.supportedFilesystems = [ "zfs" ];
      boot.loader.systemd-boot.enable = lib.mkDefault true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Required by ZFS; arbitrary but must stay stable for this host.
      networking.hostId = "9796c885";

      # Import the existing TrueNAS pool. It is NOT a boot filesystem, so use extraPools.
      boot.zfs.extraPools = [ "data-pool" ];
      # No ZFS root here; don't force-import at boot (also the 26.11 default).
      boot.zfs.forceImportRoot = false;

      services.zfs = {
        autoScrub = {
          enable = true;
          interval = "weekly";
        };
        trim.enable = true;
      };
    };
}
