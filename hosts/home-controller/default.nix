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
    self.modules.nixos.libvirt # generic libvirtd + virt-manager service
    ./haos.nix # HAOS guest: USB passthrough, cockpit UI, domain definition
    self.modules.nixos.keycloak
    self.modules.nixos.lldap # identity source of truth (Keycloak federates it)
    self.modules.nixos.metrics-agent # node_exporter, scraped over loopback
    self.modules.nixos.prometheus # loopback-only TSDB for the whole lab
    self.modules.nixos.grafana # dashboards, Keycloak OIDC
    self.modules.nixos.gatus # availability checks + status page
    self.modules.nixos.ntfy # push notifications, Gatus's alert channel
    self.modules.nixos.speedtest # WAN throughput exporter + its hourly job
    self.modules.nixos.mail # msmtp transport for backup failure mail
    self.modules.nixos.controller-restic # offsite identity backup (Storage Box)
    self.modules.nixos.auto-upgrade # unattended upgrades; last (most critical)
  ];

  system.autoUpgrade.dates = "*-*-* 06:30";

  # No aspect sets a bootloader; home-nas now declares its own systemd-boot in its host module.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  networking = {
    hostName = "home-controller";
    bridges.br0.interfaces = [ "eno1" ];
    interfaces.br0.ipv4.addresses = [
      {
        address = topology.hosts.home-controller.lanAddress;
        prefixLength = 19;
      }
    ]; # host's own IP
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "br0";
    };
    nameservers = [ topology.gatewayAddress ];
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
