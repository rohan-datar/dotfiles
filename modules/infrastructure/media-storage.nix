{ config, lib, ... }:
let
  topology = config.flake.meta.topology;
  nodeAddresses = with topology.hosts; [
    europa.lanAddress
    io.lanAddress
    ganymede.lanAddress
    callisto.lanAddress
  ];
  paperlessClients = lib.concatMapStringsSep " " (
    ip: "${ip}(rw,sync,no_subtree_check,root_squash)"
  ) nodeAddresses;
in
{
  flake.meta.topology.mediaStorage = {
    exportPath = "/mnt/data-pool/data-share/media";
    mountPoint = "/mnt/media";
  };

  # NAS side: export the media dataset over LAN NFSv4 (ADR 0014). Imported by ceres.
  # - Exported strictly to the k3s pool node LAN IPs (the dedicated 10.10.100.0/30 link is retired).
  # - Keep the existing europa exception; io, ganymede and callisto mount through
  #   the kubelet for non-root pods, so root is squashed.
  # - Firewall rules are keyed on source IPs, not NIC names, so a NAS chassis swap needs no
  #   change here. NFSv4 only from the LAN (2049; no rpcbind/mountd opened).
  flake.modules.nixos.nas-nfs = _: {
    services.nfs.server = {
      enable = true;
      exports = ''
        ${topology.mediaStorage.exportPath} ${topology.hosts.europa.lanAddress}(rw,sync,no_subtree_check,no_root_squash) ${topology.hosts.io.lanAddress}(rw,sync,no_subtree_check,root_squash) ${topology.hosts.ganymede.lanAddress}(rw,sync,no_subtree_check,root_squash) ${topology.hosts.callisto.lanAddress}(rw,sync,no_subtree_check,root_squash)
        /mnt/data-pool/paperless/media ${paperlessClients}
        /mnt/data-pool/data-share/paperless-inbox ${paperlessClients}
        /mnt/data-pool/paperless-export ${paperlessClients}
      '';
    };
    networking.firewall.extraCommands = lib.concatMapStrings (ip: ''
      iptables -A nixos-fw -p tcp --dport 2049 -s ${ip} -j nixos-fw-accept
    '') nodeAddresses;
  };

  # Media side: mount the NAS export over LAN NFSv4.2. Imported by europa.
  flake.modules.nixos.media-storage = _: {
    fileSystems."${topology.mediaStorage.mountPoint}" = {
      device = "${topology.hosts.ceres.lanAddress}:${topology.mediaStorage.exportPath}";
      fsType = "nfs";
      options = [ "nfsvers=4.2" ];
    };
  };
}
