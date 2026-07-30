{ self, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar # your admin account + ssh keys
    self.modules.nixos.server # openssh, fail2ban, ragenix, base server tools
    self.modules.nixos.intel-cpu # i5-7500T
    self.modules.nixos.ha-vm
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
  ];

  # No aspect sets a bootloader here (home-nas gets systemd-boot via nas-zfs).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 2026-07-29: this host hard-locked while completely idle — powered on but unresponsive to
  # console, network and SSH. It left no evidence at all: journal boot -1 ends mid-second at
  # 19:55:19 with every service healthy, no kernel message of any kind, no MCE/thermal/EDAC,
  # CPU at 47C and load at 0.1. home-nas and home-media were unaffected, so not electrical.
  # Cause still unidentified.
  #
  # The board exposes two hardware watchdogs (intel_oc_wdt as watchdog0, iTCO_wdt as
  # watchdog1), neither of which systemd was feeding. Feeding one means a repeat resets the
  # box in ~30s rather than sitting dead until someone holds the power button — which matters
  # because Home Assistant lives in the guest here. This is recovery, not diagnosis, and it
  # does nothing if the machine ever loses power outright.
  #
  # RebootWatchdogSec is left at systemd's 10min default, comfortably above libvirt-guests'
  # SHUTDOWN_TIMEOUT=300 so an orderly guest shutdown is never mistaken for a hang.
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
        address = "10.10.1.13";
        prefixLength = 19;
      }
    ]; # host's own IP
    defaultGateway = {
      address = "10.10.0.1";
      interface = "br0";
    };
    nameservers = [ "10.10.0.1" ];
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
