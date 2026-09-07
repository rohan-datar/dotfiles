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
    self.modules.nixos.nas-zfs
    self.modules.nixos.nas-samba
    self.modules.nixos.nas-nfs
    self.modules.nixos.nas-snapshots
    self.modules.nixos.mail # msmtp transport for the two aspects below
    self.modules.nixos.nas-alerts
    self.modules.nixos.nas-restic # offsite documents backup (Storage Box)
    self.modules.nixos.nas-cockpit
    self.modules.nixos.nas-paperless
    self.modules.nixos.metrics-agent
    self.modules.nixos.nas-metrics # zfs + smartctl exporters
    self.modules.nixos.auto-upgrade # unattended upgrades
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

  networking = {
    hostName = "home-nas";
    # Required by ZFS; arbitrary but must stay stable for this host.
    hostId = "9796c885";
    interfaces = {
      # LAN (2.5G), matches current NAS IP so Caddy/homepage upstreams don't change.
      enp2s0.ipv4.addresses = [
        {
          address = topology.hosts.home-nas.lanAddress;
          prefixLength = 19;
        }
      ]; # REPLACE iface name
      # Direct point-to-point link to home-media.
      enp3s0.ipv4.addresses = [
        {
          address = topology.hosts.home-nas.mediaLinkAddress;
          prefixLength = 30;
        }
      ]; # REPLACE iface name
    };
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "enp2s0";
    };
    nameservers = [ topology.gatewayAddress ];
    # node (9100), zfs (9134) and smartctl (9633) exporters, for the
    # controller's Prometheus. LAN interface only.
    firewall.interfaces.enp2s0.allowedTCPPorts = [
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
