{
  config,
  pkgs,
  self,
  ...
}:
let
  topology = self.meta.topology;
  # The P440ar in HBA mode exposes all three physical disks through SAT.
  # Stable by-id paths avoid probing the node’s attached iSCSI PVC devices.
  smartDevices = [
    "/dev/disk/by-id/ata-Fanxiang_S101_128GB_26081394635000016"
    "/dev/disk/by-id/ata-MB1000GCEEK_WCAW31VHVAE2"
    "/dev/disk/by-id/ata-MB1000GCEEK_WCAW36RKNDAF"
  ];
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
    self.modules.nixos.smart-alerts # SMART journal + email alerts
    self.modules.nixos.auto-upgrade # unattended upgrades
    self.modules.nixos.mail # msmtp transport for backup failure mail
    self.modules.nixos.onedev-restic # offsite OneDev backup (Storage Box)
    self.modules.nixos.restic-nas-target # on-site repo for home-nas k8s volume backups
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  age.secrets.k3s-token.file = ../../secrets/k3s-token.age;

  services.k3s = {
    serverAddr = "https://${topology.hosts.io.lanAddress}:6443";
    tokenFile = config.age.secrets.k3s-token.path;
  };

  # PVCs live on the Btrfs RAID1 at this path (disks.nix, mounted nofail so the host
  # still boots). Without the mount, local-path would hand pods empty directories on
  # the boot SSD (as happened on 2026-11-06), so k3s must not start without it.
  systemd.services.k3s.unitConfig.RequiresMountsFor = [ "/var/lib/rancher/k3s/storage" ];

  services.prometheus.exporters.smartctl = {
    enable = true; # :9633, scraped only by home-controller
    devices = map (device: "${device} -d sat") smartDevices;
  };

  services.smartd = {
    autodetect = false;
    devices = map (device: {
      inherit device;
      options = "-d sat";
    }) smartDevices;
  };

  # Headless NVIDIA Tesla P100 PCIe 16GB (GP100, Pascal) in PCIe Slot 3.
  # NVIDIA 595+ dropped Pascal; the 580 LTSB proprietary driver supports GP100.
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.kernelModules = [
    "nvidia"
    "nvidia_uvm"
  ];
  hardware = {
    graphics.enable = true;
    nvidia = {
      branch = "legacy_580";
      open = false;
      nvidiaSettings = false;
      nvidiaPersistenced = true;
    };
    nvidia-container-toolkit.enable = true;
  };
  environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];

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
    # smartctl_exporter (:9633): Prometheus on home-controller only.
    firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s ${topology.hosts.home-controller.lanAddress} --dport 9633 -j nixos-fw-accept
    '';
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
