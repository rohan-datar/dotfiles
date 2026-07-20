{ self, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    self.modules.nixos.rdatar # your admin account + ssh keys
    self.modules.nixos.server # openssh, fail2ban, agenix, base server tools
    self.modules.nixos.intel-cpu # i5-7500T
    self.modules.nixos.ha-vm
    # Phase 5 adds: self.modules.nixos.authentik
    # Phase 7 adds: self.modules.nixos.monitoring
  ];

  # No aspect sets a bootloader here (home-nas gets systemd-boot via nas-zfs).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  networking = {
    hostName = "home-server";
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
