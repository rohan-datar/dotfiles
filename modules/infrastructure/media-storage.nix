{ config, ... }:
let
  topology = config.flake.meta.topology;
in
{
  flake.meta.topology.mediaStorage = {
    exportPath = "/mnt/data-pool/data-share/media";
    mountPoint = "/mnt/media";
  };

  # NAS side: export the media dataset over NFS to home-media's media link
  # address. Imported by home-nas.
  flake.modules.nixos.nas-nfs = _: {
    services.nfs.server = {
      enable = true;
      exports = ''
        ${topology.mediaStorage.exportPath} ${topology.hosts.home-media.mediaLinkAddress}(rw,sync,no_subtree_check,no_root_squash)
      '';
    };
    networking.firewall = {
      # NFSv4 only (single port), and only on the direct link to home-media, not the LAN.
      interfaces."enp3s0".allowedTCPPorts = [ 2049 ];
    };
  };

  # Media side: mount the NAS export. Imported by home-media.
  flake.modules.nixos.media-storage = _: {
    fileSystems."${topology.mediaStorage.mountPoint}" = {
      device = "${topology.hosts.home-nas.mediaLinkAddress}:${topology.mediaStorage.exportPath}";
      fsType = "nfs";
    };
  };
}
