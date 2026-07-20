_: {
  flake.modules.nixos.nas-nfs = _: {
    services.nfs.server = {
      enable = true;
      # 10.10.100.1 is this NAS's point-to-point IP to home-media.
      exports = ''
        /mnt/data-pool/data-share/media 10.10.100.2(rw,sync,no_subtree_check,no_root_squash)
      '';
    };
    networking.firewall = {
      # NFSv4 only (single port), and only on the direct link to home-media, not the LAN.
      interfaces."enp3s0".allowedTCPPorts = [ 2049 ];
    };
  };
}
