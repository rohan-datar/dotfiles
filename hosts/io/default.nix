{ self, ... }:
let
  topology = self.meta.topology;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar # admin account + ssh keys
    self.modules.nixos.server # openssh, fail2ban, ragenix, base server tools
    self.modules.nixos.intel-cpu # N100
    self.modules.nixos.intel-gpu # N100 iGPU
    self.modules.nixos.k3s-server # initial k3s control-plane / sandbox node
    self.modules.nixos.metrics-agent # node_exporter (:9100) for Prometheus
    self.modules.nixos.auto-upgrade # unattended upgrades
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  networking = {
    hostName = "io";
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = topology.hosts.io.lanAddress;
        prefixLength = 19;
      }
    ];
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "enp1s0";
    };
    nameservers = [ topology.gatewayAddress ];
    # SSH and node_exporter on the LAN interface.
    firewall.interfaces.enp1s0.allowedTCPPorts = [
      22
      9100
    ];
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
