{ config, self, ... }:
let
  topology = self.meta.topology;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar # admin account + ssh keys
    self.modules.nixos.server # openssh, fail2ban, ragenix, base server tools
    self.modules.nixos.intel-cpu # Xeon E5-2680 v4
    self.modules.nixos.k3s-agent # heavy k3s worker node joined to io
    self.modules.nixos.metrics-agent # node_exporter (:9100) for Prometheus
    self.modules.nixos.auto-upgrade # unattended upgrades
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  age.secrets.k3s-token.file = ../../secrets/k3s-token.age;

  services.k3s = {
    serverAddr = "https://${topology.hosts.io.lanAddress}:6443";
    tokenFile = config.age.secrets.k3s-token.path;
  };

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  networking = {
    hostName = "ganymede";
    interfaces.ens1f0.ipv4.addresses = [
      {
        address = topology.hosts.ganymede.lanAddress;
        prefixLength = 19;
      }
    ];
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "ens1f0";
    };
    nameservers = [ topology.gatewayAddress ];
    # SSH and node_exporter on the 10GbE LAN interface.
    firewall.interfaces.ens1f0.allowedTCPPorts = [
      22
      9100
    ];
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
