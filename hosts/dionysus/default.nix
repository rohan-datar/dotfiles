{ pkgs, ... }:
let
  name = "home-media";
  configName = builtins.baseNameOf (builtins.toString ./.);
in
{
  imports = [
    ./hardware-configuration.nix
    ./user.nix
    ./disks.nix
  ];

  olympus = {
    aspects = {
      graphical.enable = false;
      server.enable = true;
    };

    system = {
      cpu = "intel";
      gpu = "intel";
      bluetooth.enable = true;
    };

    services = {
      arr.enable = true;
      homepage.enable = true;
    };
    environment.flakePath = "/home/rdatar/nix";

    packages = {
      inherit (pkgs)
        gcc
        curl
        cifs-utils
        nh
        ;

    };
  };

  boot.kernelModules = [ "btusb" ];

  services.openssh.enable = true;

  networking = {
    hostName = name;
    interfaces = {
      enp1s0.ipv4.addresses = [
        {
          address = "10.10.1.11";
          prefixLength = 19;
        }
      ];

      enp3s0.ipv4.addresses = [
        {
          address = "10.10.100.2";
          prefixLength = 30;
        }
      ];
    };
    defaultGateway = {
      address = "10.10.0.1";
      interface = "enp1s0";
    };

    nameservers = [ "10.10.0.1" ];
  };

  fileSystems = {
    "/mnt/media" = {
      device = "10.10.100.1:/mnt/data-pool/data-share/media";
      fsType = "nfs";
    };

  };

  environment.variables.NIX_CONFIG_NAME = configName;
  system.stateVersion = "24.11";
}
