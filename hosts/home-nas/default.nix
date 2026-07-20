{ self, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar # your admin account + ssh keys
    self.modules.nixos.server # openssh, fail2ban, agenix, base server tools
    self.modules.nixos.intel-cpu # N100
    self.modules.nixos.nas-zfs
    self.modules.nixos.nas-samba
    self.modules.nixos.nas-nfs
    self.modules.nixos.nas-snapshots
    self.modules.nixos.nas-alerts
    self.modules.nixos.nas-cockpit
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
    interfaces = {
      # LAN (2.5G), matches current NAS IP so Caddy/homepage upstreams don't change.
      enp2s0.ipv4.addresses = [
        {
          address = "10.10.1.10";
          prefixLength = 19;
        }
      ]; # REPLACE iface name
      # Direct point-to-point link to home-media (other end is 10.10.100.2/30).
      enp3s0.ipv4.addresses = [
        {
          address = "10.10.100.1";
          prefixLength = 30;
        }
      ]; # REPLACE iface name
    };
    defaultGateway = {
      address = "10.10.0.1";
      interface = "enp2s0";
    };
    nameservers = [ "10.10.0.1" ];
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
