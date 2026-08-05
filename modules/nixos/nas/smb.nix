_: {
  flake.modules.nixos.nas-samba = _: {
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
          "force create mode" = "0664";
          "force directory mode" = "0775";
        };

        macos-backup = {
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
