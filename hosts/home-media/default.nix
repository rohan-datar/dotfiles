{ lib, self, ... }:
let
  topology = self.meta.topology;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar
    self.modules.nixos.server
    self.modules.nixos.arr
    self.modules.nixos.media-books
    self.modules.nixos.homepage
    self.modules.nixos.intel-cpu
    self.modules.nixos.intel-gpu
    self.modules.nixos.bluetooth
    self.modules.nixos.media-oauth2-proxy
    self.modules.nixos.media-ingress
    self.modules.nixos.metrics-agent
    self.modules.nixos.media-watchdog # watches home-controller from the outside
    self.modules.nixos.auto-upgrade # unattended upgrades; canary slot, first
    self.modules.nixos.warpgate
    self.modules.nixos.mail # msmtp transport for the backup-failure alert below
    self.modules.nixos.media-restic
    self.modules.nixos.media-storage
  ];

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  system.autoUpgrade.dates = "*-*-* 03:30";

  # `services.userborn` requires `system.activationScripts.users == ""`.
  # nixarr's Seerr module extends `system.activationScripts.users.deps`, which
  # turns it into an attrset and conflicts with userborn.
  services.userborn.enable = lib.mkForce false;

  boot.kernelModules = [ "btusb" ];

  networking = {
    interfaces = {
      enp1s0.ipv4.addresses = [
        {
          address = topology.hosts.home-media.lanAddress;
          prefixLength = 19;
        }
      ];

      enp3s0.ipv4.addresses = [
        {
          address = topology.hosts.home-media.mediaLinkAddress;
          prefixLength = 30;
        }
      ];
    };
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "enp1s0";
    };

    nameservers = [ topology.gatewayAddress ];

    # node_exporter, for the controller's Prometheus. LAN interface only.
    firewall.interfaces.enp1s0.allowedTCPPorts = [ 9100 ];
  };

  time.timeZone = "America/Chicago";

  system.stateVersion = "25.11";
}
