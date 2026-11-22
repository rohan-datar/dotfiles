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
    self.modules.nixos.k3s-server
    self.modules.nixos.k3s-bootstrap # sole writer of the CNI and Gateway API CRD AddOns
    self.modules.nixos.metrics-agent # node_exporter (:9100) for Prometheus
    self.modules.nixos.auto-upgrade # unattended upgrades
    self.modules.nixos.mail # msmtp transport for backup failure mail
    self.modules.nixos.k3s-etcd-restic # offsite etcd snapshots + server token (Storage Box)
  ];

  # Host-local SSH access. Keep these keys out of the shared root key list.
  users.users.rdatar.openssh.authorizedKeys.keys = [
    # Termix
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICq10Ke+doDqkkH13k0d1Fgp2EoDGlkhJtVf5B4ffVb6 termix"

    # Warpgate
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHIZy+xl+7QCrfBYb7REzjtFIoEXUZuw4uAIurOFYj2"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  services.k3s.clusterInit = true;
  services.keepalived.vrrpInstances.k3s-api = {
    interface = "enp1s0";
    priority = 150;
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

  # etcd server: own upgrade window, apart from the other servers (see auto-upgrade.nix).
  system.autoUpgrade.dates = "*-*-* 04:00";

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
