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
    self.modules.nixos.media-storage
  ];

  # Termix: add only this host's public key here, not the private key.
  users.users.rdatar.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRiVyvaYnCdl0vptlAYqvaf4+0M4HAVfOB7W6GCZROn termix"
  ];

  # Recovery bastion staging: private SSH port-forward only, no Caddy route.
  # Use fresh state; the retired Warpgate deployment used /var/lib/warpgate.
  services.warpgate = {
    enable = true;
    settings = {
      database_url = "sqlite:/var/lib/warpgate-recovery/db";
      http = {
        listen = "127.0.0.1:8888";
        certificate = "/var/lib/warpgate-recovery/tls.certificate.pem";
        key = "/var/lib/warpgate-recovery/tls.key.pem";
        trust_x_forwarded_headers = false;
      };
      ssh = {
        enable = false;
        keys = "/var/lib/warpgate-recovery/ssh-keys";
      };
      sso_providers = [ ];
    };
  };
  systemd.services.warpgate.serviceConfig.StateDirectory = lib.mkForce "warpgate-recovery";

  age.secrets.k3s-token.file = ../../secrets/k3s-token.age;

  services.k3s = {
    serverAddr = "https://${topology.hosts.io.lanAddress}:6443";
    tokenFile = config.age.secrets.k3s-token.path;
    # Native media services are gone (Wave 4, 2026-11-21): europa is a regular agent. Reserve
    # only what the OS itself needs. Note: k3s applies --node-taint at registration only, so the
    # old homelab.dev/staging taint must also be removed with kubectl.
    extraKubeletConfig = {
      systemReserved = {
        cpu = "250m";
        memory = "1Gi";
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
