{ self, lib, ... }:
let
  topology = self.meta.topology;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar # your admin account + ssh keys
    self.modules.nixos.server # openssh, fail2ban, ragenix, base server tools
    self.modules.nixos.intel-cpu # N100
    self.modules.nixos.k3s-joining-server # tainted, embedded etcd + API
    self.modules.nixos.nas-zfs
    self.modules.nixos.nas-samba
    self.modules.nixos.nas-nfs
    self.modules.nixos.nas-iscsi # k3s durable storage tier (ADR 0014)
    self.modules.nixos.nas-k8s-volume-backup # zvol clone → restic (Storage Box + ganymede)
    self.modules.nixos.nas-snapshots
    self.modules.nixos.mail # msmtp transport for the two aspects below
    self.modules.nixos.nas-alerts
    self.modules.nixos.nas-restic # offsite documents backup (Storage Box)
    self.modules.nixos.metrics-agent
    self.modules.nixos.nas-metrics # zfs + smartctl exporters
    self.modules.nixos.auto-upgrade # unattended upgrades
  ];

  # Termix: add only this host's public key here, not the private key.
  users.users.rdatar.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIg+/4BKXGCepaFElPicq5L0yfeuCoE7C4uZt2sTod7 ceres-termix"
  ];

  # Match the UID/GID rdatar had on TrueNAS so ownership of existing pool data
  # (written over SMB as uid/gid 3001) stays correct. Other hosts keep uid 1000.
  users.users.rdatar = {
    uid = 3001;
    group = "rdatar";
    extraGroups = [ "media" ];
  };
  users.groups.rdatar.gid = 3001;

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  services.k3s = {
    extraFlags = lib.mkAfter [ "--node-taint=node-role.kubernetes.io/control-plane=:NoSchedule" ];
    extraKubeletConfig = {
      # 8 GiB ZFS ARC + native NAS services/OCR and host overhead. Leave
      # headroom for etcd/apiserver and node DaemonSets (the taint is not a cap).
      systemReserved = {
        cpu = "1000m";
        memory = "11Gi";
      };
      kubeReserved = {
        cpu = "500m";
        memory = "2Gi";
      };
    };
  };
  services.keepalived.vrrpInstances.k3s-api = {
    interface = "enp2s0";
    priority = 120;
  };

  networking = {
    hostName = "ceres";
    # Required by ZFS; arbitrary but must stay stable for this host.
    hostId = "9796c885";
    interfaces = {
      # LAN (2.5G), matches current NAS IP so Caddy/homepage upstreams don't change.
      enp2s0.ipv4.addresses = [
        {
          address = topology.hosts.ceres.lanAddress;
          prefixLength = 19;
        }
      ]; # REPLACE iface name
    };
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "enp2s0";
    };
    nameservers = [ topology.gatewayAddress ];
    # SSH, plus the node (9100), zfs (9134) and smartctl (9633) exporters for
    # the controller's Prometheus. LAN interface only.
    firewall.interfaces.enp2s0.allowedTCPPorts = [
      22
      9100
      9134
      9633
    ];
  };

  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ]; # 8 GiB
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Import the existing TrueNAS pool. It is NOT a boot filesystem, so use extraPools.
  boot.zfs.extraPools = [ "data-pool" ];
  # No ZFS root here; don't force-import at boot (also the 26.11 default).
  boot.zfs.forceImportRoot = false;

  # Compressed RAM-backed swap: absorbs transient spikes (backups, OCR bursts)
  # without swap-on-ZFS deadlocks. systemd-oomd handles real leaks above this.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
