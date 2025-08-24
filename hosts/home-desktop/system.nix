{
  config,
  pkgs,
  inputs,
  ...
}:
{
  # custom options
  olympus = {
    graphical = {
      enable = true;
      windowManager = "hyprland";
    };

    emulation = {
      systems = [
        "aarch64-linux"
        "x86_64-windows"
      ];
    };

    printing.enable = true;
    bluetooth.enable = true;
    cpu = "intel";
    gpu = "nvidia";
  };

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    devices = [ "nodev" ];
    efiSupport = true;
    useOSProber = true;
    configurationLimit = 50;
    efiInstallAsRemovable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelParams = [
    "initcall_blacklist=simpledrm_platform_driver_init"
    "nvidia.NVreg_OpenRmEnableUnsupportedGpus=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia-drm.modeset=1"
  ];

  networking.hostName = "home-desktop"; # Define your hostname.
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "10.10.0.1"
    "1.1.1.1"
  ];
  services.openssh.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rdatar = {
    isNormalUser = true;
    description = "Rohan Datar";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "rdatar";
}
