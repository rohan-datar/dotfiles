{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  topology = self.meta.topology;
  nvidia-smi = lib.getExe' config.hardware.nvidia.package "nvidia-smi";
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
    self.modules.nixos.gpu-metrics # P100 telemetry via node_exporter textfile (no hwmon/iLO visibility)
    self.modules.nixos.ocsd-thermal-bridge # P100 temperature -> iLO fan control via OCSD (27-PCI 3)
    self.modules.nixos.smart-alerts # SMART journal + email alerts
    self.modules.nixos.auto-upgrade # unattended upgrades
    self.modules.nixos.albedo-ops # albedo VM: observe + deploy-merged-main (tiers)
    self.modules.nixos.mail # msmtp transport for backup failure mail
    self.modules.nixos.onedev-restic # offsite OneDev backup (Storage Box)
    self.modules.nixos.restic-nas-target # on-site repo for ceres k8s volume backups
    self.modules.nixos.pallas-vm # persistent albedo microVM on br0 (ADR 0012)
  ];

  # Termix: add only this host's public key here, not the private key.
  users.users.rdatar.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBbv16tZ3Tmi1CruX+HUzWj1nOgvs75yDSpJZtKmWKM3 termix"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  age.secrets.k3s-token.file = ../../secrets/k3s-token.age;

  services.k3s = {
    serverAddr = "https://${topology.k3sApiAddress}:6443";
    tokenFile = config.age.secrets.k3s-token.path;
  };

  # PVCs live on the Btrfs RAID1 at this path (disks.nix, mounted nofail so the host
  # still boots). Without the mount, local-path would hand pods empty directories on
  # the boot SSD (as happened on 2026-11-06), so k3s must not start without it.
  systemd.services.k3s.unitConfig.RequiresMountsFor = [ "/var/lib/rancher/k3s/storage" ];

  services.prometheus.exporters.smartctl = {
    enable = true; # :9633, scraped only by callisto
    # smartctl_exporter takes "path;type" (not smartctl's "-d" flag).
    devices = map (device: "${device};sat") smartDevices;
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

  # Cap the P100 at 140 W (benchmark envelope: llm-bench phase-a-3 requires <= 145 W). The passive card + printed duct cannot dissipate the
  # full 250 W board power at Gen9 baseline fans: llm-bench phase-a-1 (2026-11-23)
  # hit 78 °C with driver SW thermal slowdown (clock reason 0x20) in under three
  # minutes, because iLO 4 cannot read a non-HPE GPU's temperature. The OCSD bridge
  # (ocsd-thermal-bridge) now feeds it to iLO; 140 W + bridge passed phase-a-4. 160 W matches the Pascal llama.cpp community benchmark level and
  # decode is memory-bound, so the tokens/s cost is modest. Raise or remove only
  # after sustained cooling validation.
  systemd.services.nvidia-power-cap = {
    description = "Tesla P100 power cap (140 W)";
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # -pm 1 is idempotent alongside nvidia-persistenced. Re-applied on boot; a
    # future refinement could re-apply on nvidia module (re)load via udev.
    script = ''
      ${nvidia-smi} -pm 1
      ${nvidia-smi} -pl 140
    '';
  };

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  # Keep the microVM's LAN bridge L2-only for transit frames, as on callisto:
  # k3s-node loads br_netfilter, but bridged guest traffic must not go through
  # Kubernetes/Cilium's IP FORWARD hooks. The guest runs its own firewall.
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
  };

  networking = {
    hostName = "ganymede";
    # ens1f0 is now a bridge port; br0 carries the host IP (and k3s nodeIP stays
    # 10.10.1.15). The kernel bridge takes the lowest port MAC, i.e. ens1f0's.
    bridges.br0 = {
      interfaces = [ "ens1f0" ];
      rstp = false;
    };
    # Pin the bridge to ens1f0's MAC so a lower-addressed tap joining later can't
    # change the host's L2 identity (router ARP, VIP announcements). Read 2026-11-22.
    interfaces.br0.macAddress = "14:02:ec:89:da:c0";
    interfaces.br0.ipv4.addresses = [
      {
        address = topology.hosts.ganymede.lanAddress;
        prefixLength = 19;
      }
    ];
    defaultGateway = {
      address = topology.gatewayAddress;
      interface = "br0";
    };
    nameservers = [ topology.gatewayAddress ];
    # SSH and node_exporter on the 10GbE LAN bridge.
    firewall.interfaces.br0.allowedTCPPorts = [
      22
      9100
    ];
    # smartctl_exporter (:9633): native Prometheus plus Cilium-filtered scrapers.
    firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s ${topology.hosts.callisto.lanAddress} --dport 9633 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp -s 10.42.0.0/16 --dport 9633 -j nixos-fw-accept
    '';
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
