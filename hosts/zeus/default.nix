{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  name = "home-desktop";
  # Extract the config name from the flake
  configName = builtins.baseNameOf (builtins.toString ./.);
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [
    ./hardware-configuration.nix
    ./user.nix
  ];

  olympus = {
    aspects.graphical = {
      enable = true;
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

    services.printing.enable = true;

    environment.flakePath = "/home/rdatar/nix";

    packages = {
      inherit (pkgs)
        sbctl # NEEDED FOR SECURE BOOT
        cargo
        clang
        gcc
        nodejs
        lua
        gnumake
        cacert
        wl-clipboard
        ungoogled-chromium
        libnotify
        glib
        # swift
        thunderbird
        cifs-utils
        nautilus
        font-manager
        beeper
        mpv
        ;
      emacs = inputs.editorconfig.packages.${system}.rdmacs;
      inherit (inputs.zen-browser.packages."${system}") default;
    };
  };

  services.openssh.enable = true;
  # see https://www.openwall.com/lists/oss-security/2025/12/28/4
  systemd.generators.systemd-ssh-generator = "/dev/null";
  systemd.sockets.sshd-unix-local.enable = lib.mkForce false;
  systemd.sockets.sshd-vsock.enable = lib.mkForce false;

  services.emacs = {
    enable = true;
    package = inputs.editorconfig.packages.${system}.rdmacs;
    startWithGraphical = true; # Wait for graphical-session.target
  };

  services.lorri.enable = true;
  # virtualisation.docker = {
  #   enable = true;
  #   rootless = {
  #     enable = true;
  #     setSocketVariable = true;
  #   };
  # };

  networking = {
    hostName = name; # Define your hostname.
    networkmanager.enable = true;
    nameservers = [ "10.10.0.1" ];
    enableIPv6 = false;
  };

  time = {
    timeZone = "America/Chicago";
    hardwareClockInLocalTime = true;
  };

  environment.variables.NIX_CONFIG_NAME = configName;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
