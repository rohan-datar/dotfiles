{ config, lib, ... }:
let
  topology = config.flake.meta.topology;
in
{
  flake.meta.topology.mediaStorage = {
    exportPath = "/mnt/data-pool/data-share/media";
    mountPoint = "/mnt/media";
  };

  # NAS side: export the media dataset over NFS (ADR 0014). Imported by home-nas.
  # - LAN: the k3s nodes, for the shared `media` PersistentVolume and europa's native mount.
  #   europa keeps no_root_squash like its old link export (native services); io and
  #   ganymede only ever mount through the kubelet for non-root pods, so root is squashed.
  # - The 10.10.100.0/30 point-to-point link stays only until europa's mount moves to the
  #   LAN; then that entry and the enp3s0 rule go.
  # Firewall rules are keyed on source IPs, not NIC names, so a NAS chassis swap needs no
  # change here. NFSv4 only from the LAN (2049; no rpcbind/mountd opened).
  flake.modules.nixos.nas-nfs = _: {
    services.nfs.server = {
      enable = true;
      exports = ''
        ${topology.mediaStorage.exportPath} ${topology.hosts.europa.mediaLinkAddress}(rw,sync,no_subtree_check,no_root_squash) ${topology.hosts.europa.lanAddress}(rw,sync,no_subtree_check,no_root_squash) ${topology.hosts.io.lanAddress}(rw,sync,no_subtree_check,root_squash) ${topology.hosts.ganymede.lanAddress}(rw,sync,no_subtree_check,root_squash)
      '';
    };
    networking.firewall = {
      interfaces."enp3s0".allowedTCPPorts = [ 2049 ];
      extraCommands =
        lib.concatMapStrings
          (ip: ''
            iptables -A nixos-fw -p tcp --dport 2049 -s ${ip} -j nixos-fw-accept
          '')
          [
            topology.hosts.europa.lanAddress
            topology.hosts.io.lanAddress
            topology.hosts.ganymede.lanAddress
          ];
    };
  };

  # Media side: mount the NAS export. Imported by europa.
  flake.modules.nixos.media-storage = _: {
    fileSystems."${topology.mediaStorage.mountPoint}" = {
      device = "${topology.hosts.home-nas.mediaLinkAddress}:${topology.mediaStorage.exportPath}";
      fsType = "nfs";
    };
  };
}
