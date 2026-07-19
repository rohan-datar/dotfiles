_: {
  flake.modules.nixos.nas-samba = _: {
    # On-disk media files are group GID 169 — home-media's nixarr `media` group,
    # written over NFS with raw numeric IDs (confirmed via ls -n before migration).
    # Match it here so rdatar (extraGroups media) keeps SMB write access to the tree.
    # rdatar (uid/gid 3001) is overridden in hosts/home-nas/default.nix.
    users.groups.media.gid = 169;

    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = "home-nas";
          "min protocol" = "SMB3";
          "server smb encrypt" = "required";
          # macOS compatibility (fruit) globals:
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:metadata" = "stream";
          "fruit:posix_rename" = "yes";
          "fruit:model" = "MacSamba";
        };

        data-share = {
          path = "/mnt/data-pool/data-share";
          browseable = "yes";
          writable = "yes";
          "valid users" = "rdatar";
        };

        macos-backup = {
          # Same share name/path as TrueNAS so the Mac's Time Machine target URL is unchanged.
          # The 1T cap also exists as a ZFS quota on the dataset (survives the import).
          path = "/mnt/data-pool/macos-backup";
          browseable = "yes";
          writable = "yes";
          "valid users" = "rdatar";
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = "1T";
        };
      };
    };

    # Advertise over Bonjour so macOS auto-discovers the Time Machine target.
    services.avahi = {
      enable = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
      nssmdns4 = true;
    };
  };
}
