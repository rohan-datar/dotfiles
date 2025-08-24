{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./user.nix
  ];

  olympus = {
    aspects.graphical = {
      enable = true;
      windowManager = "hyprland";
    };

    system = {
      emulation = {
        enable = true;
        systems = [
          "aarch64-linux"
          "x86_64-windows"
        ];
      };

      bluetooth.enable = true;
      sound.enable = true;

      cpu = "intel";
      gpu = "nvidia";
    };

    services.printing = true;

    environment.flakePath = "/home/rdatar/nix";
  };

  programs.defaults = {
    shell = "fish";
  };

  packages = with pkgs; [
    kitty
    cargo
    clang
    gcc
    nodejs
    lua
    gnumake
    cacert
    wl-clipboard
    ungoogled-chromium
    obsidian
    inputs.zen-browser.packages."${system}".default
    libnotify
    glib
    swift
    thunderbird
    cifs-utils
    nautilus
    font-manager
    beeper
  ];

  services.openssh.enable = true;

  networking.hostName = "home-desktop"; # Define your hostname.
  networking.nameservers = [
    "10.10.0.1"
    "1.1.1.1"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
