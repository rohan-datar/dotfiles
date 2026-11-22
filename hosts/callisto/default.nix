{ self, ... }:
let
  topology = self.meta.topology;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar # your admin account + ssh keys
    self.modules.nixos.server # openssh, fail2ban, ragenix, base server tools
    self.modules.nixos.intel-cpu # i5-7500T
    self.modules.nixos.k3s-joining-server # embedded etcd + light workloads
    self.modules.nixos.libvirt # generic libvirtd + virt-manager service
    ./haos.nix # HAOS guest: USB passthrough, domain definition
    self.modules.nixos.authelia # SSO: forward auth + OIDC provider
    self.modules.nixos.lldap # identity source of truth for Authelia and Jellyfin
    self.modules.nixos.metrics-agent # node_exporter, scraped by k3s Prometheus
    self.modules.nixos.gatus # independent watchdog and status page
    self.modules.nixos.speedtest # WAN throughput exporter + its hourly job
    self.modules.nixos.mail # msmtp transport for backup failure mail
    self.modules.nixos.controller-restic # offsite identity backup (Storage Box)
    self.modules.nixos.auto-upgrade # unattended upgrades; last (most critical)
  ];

  # Host-local SSH access. Keep these keys out of the shared root key list.
  users.users.rdatar.openssh.authorizedKeys.keys = [
    # Termix
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYyMqsBczs9uKkrrEli7ex/RinG0qMJqrYJO1de64S9 callisto-termix"

    # Warpgate
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHIZy+xl+7QCrfBYb7REzjtFIoEXUZuw4uAIurOFYj2"
  ];

  # etcd server: own upgrade window, apart from io (04:00) and ceres (05:00).
  system.autoUpgrade.dates = "*-*-* 06:30";

  # No aspect sets a bootloader; ceres now declares its own systemd-boot in its host module.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  services.k3s.extraKubeletConfig = {
    # HAOS is configured for 4 GiB; the whole host used ~5.2 GiB before k3s.
    # Round up for guest overhead and growth in native services, separately
    # budget the control plane; do not count the HAOS guest as reclaimable RAM.
    systemReserved = {
      cpu = "1000m";
      memory = "7Gi";
    };
    kubeReserved = {
      cpu = "500m";
      memory = "2Gi";
    };
  };
  services.keepalived.vrrpInstances.k3s-api = {
    interface = "br0";
    priority = 100;
  };

  # Keep libvirt's HAOS LAN bridge L2-only for transit frames. k3s-node
  # loads br_netfilter, but bridged guest traffic previously bypassed host
  # iptables; do not send it through Kubernetes/Cilium's IP FORWARD hooks.
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
  };

  networking = {
    hostName = "callisto";
    bridges.br0.interfaces = [ "eno1" ];
    interfaces.br0.ipv4.addresses = [
      {
        address = topology.hosts.callisto.lanAddress;
        prefixLength = 19;
      }
    ]; # host's own IP
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "br0";
    };
    nameservers = [ topology.gatewayAddress ];
    # SSH on the LAN bridge only.
    firewall.interfaces.br0.allowedTCPPorts = [ 22 ];
    firewall.extraCommands = ''
      # Prometheus pod scrapes are restricted by the cluster Cilium egress policy.
      iptables -A nixos-fw -p tcp -s 10.42.0.0/16 --dport 9100 -j nixos-fw-accept
    '';
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
