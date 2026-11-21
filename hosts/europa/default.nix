{
  config,
  lib,
  self,
  ...
}:
let
  topology = self.meta.topology;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar
    self.modules.nixos.server
    self.modules.nixos.intel-cpu
    self.modules.nixos.intel-gpu
    self.modules.nixos.bluetooth
    self.modules.nixos.k3s-agent
    self.modules.nixos.metrics-agent
    self.modules.nixos.media-watchdog # watches home-controller from the outside
    self.modules.nixos.auto-upgrade # unattended upgrades; canary slot, first
    self.modules.nixos.mail # msmtp transport for backup failure mail
    self.modules.nixos.europa-restic # offsite media-state backup (Storage Box)
    self.modules.nixos.media-storage
  ];

  age.secrets.k3s-token.file = ../../secrets/k3s-token.age;

  services.k3s = {
    serverAddr = "https://${topology.hosts.io.lanAddress}:6443";
    tokenFile = config.age.secrets.k3s-token.path;
    # Native media services still run on europa during Stage 1: reserve ~4 GiB for OS + media
    # processes and taint the node so only DaemonSets (cilium, cilium-envoy) schedule here
    # until media waves begin.
    nodeTaint = [ "homelab.dev/staging=true:NoSchedule" ];
    extraKubeletConfig = {
      systemReserved = {
        cpu = "500m";
        memory = "4Gi";
      };
      kubeReserved = {
        cpu = "250m";
        memory = "768Mi";
      };
    };
  };

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  system.autoUpgrade.dates = "*-*-* 03:30";

  # Kept off while nixarr still manages service users on europa; re-enable separately
  # with dry-activate UID/GID verification once nixarr is retired.
  services.userborn.enable = lib.mkForce false;

  boot.kernelModules = [ "btusb" ];

  networking = {
    hostName = "europa";
    interfaces = {
      enp1s0.ipv4.addresses = [
        {
          address = topology.hosts.europa.lanAddress;
          prefixLength = 19;
        }
      ];
    };
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "enp1s0";
    };

    nameservers = [ topology.gatewayAddress ];

    # SSH, and node_exporter for the controller's Prometheus. LAN interface
    # only, so the VPN namespace on wg-br cannot reach sshd.
    firewall.interfaces.enp1s0.allowedTCPPorts = [
      22
      9100
    ];
  };

  time.timeZone = "America/Chicago";

  system.stateVersion = "25.11";
}
