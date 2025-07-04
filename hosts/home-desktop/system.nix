{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Bootloader.
  boot.loader.grub = {
    enable = true;
    devices = ["nodev"];
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
    "nvidia-drm.fbdev=1"
  ];

  # allows for running binaries compiled for different architectures
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "x86_64-windows"
  ];

  networking.hostName = "home-desktop"; # Define your hostname.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.nameservers = ["10.10.0.1" "1.1.1.1"];
  services.openssh.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # some settings for wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";

    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "0";
    WLR_DRM_NO_ATOMIC = "1";

    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt5ct";

    GDK_SCALE = "2";

    ELECTRON_OZONE_PLATFORM_HINT = "auto";

    NVD_BACKEND = "direct";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["nvidia"];
  };

  hardware = let
    # driverPkg = config.boot.kernelPackages.nvidiaPackages.beta;
  in {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = false;
      # package = driverPkg;
    };

    # bluetooth
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };

  services.blueman.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rdatar = {
    isNormalUser = true;
    description = "Rohan Datar";
    extraGroups = ["networkmanager" "wheel"];
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [xdg-desktop-portal-hyprland];
  };
  environment.systemPackages = [
    (
      pkgs.catppuccin-sddm.override {
        flavor = "mocha";
        font = "JetBrainsMono Nerd Font Propo";
        fontSize = "12";
        background = "~/.local/share/backgrounds/nixos-wallpaper-catppuccin-mocha.png";
        loginBackground = true;
      }
    )
  ];

  services = {
    displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      autoNumlock = true;
      wayland.enable = true;
      theme = "catppuccin-mocha";
    };
  };

  nix = {
    gc = {
      automatic = true;
      randomizedDelaySec = "14m";
      options = "--delete-older-than 15d";
    };

    optimise = {
      automatic = true;
    };
  };

  # Enable automatic login for the user.
  # services.displayManager.autoLogin.enable = true;
  # services.displayManager.autoLogin.user = "rdatar";
}
