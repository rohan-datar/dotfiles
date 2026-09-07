_: {
  flake.modules.nixos.nas-zfs = {
    boot.supportedFilesystems = [ "zfs" ];
    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
      trim.enable = true;
    };
  };
}
