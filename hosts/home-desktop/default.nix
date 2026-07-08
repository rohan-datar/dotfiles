{
  pkgs,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [
    ./hardware-configuration.nix
    ./user.nix
    self.modules.nixos.rdatar
    self.modules.nixos.graphical
    self.modules.nixos.intel-cpu
    self.modules.nixos.nvidia
    self.modules.nixos.sound
    self.modules.nixos.bluetooth
    self.modules.nixos.emulation
    self.modules.nixos.printing
  ];

  environment.variables = {
    FLAKE = "/home/rdatar/nix";
    NH_FLAKE = "/home/rdatar/nix";
  };

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "x86_64-windows"
  ];

  environment.systemPackages = [
    pkgs.sbctl # NEEDED FOR SECURE BOOT
    pkgs.cargo
    pkgs.clang
    pkgs.gcc
    pkgs.nodejs
    pkgs.lua
    pkgs.gnumake
    pkgs.cacert
    pkgs.wl-clipboard
    pkgs.libnotify
    pkgs.glib
    pkgs.swift
    # pkgs.thunderbird
    pkgs.cifs-utils
    pkgs.nautilus
    pkgs.font-manager
    pkgs.beeper
    pkgs.mpv
    inputs.editorconfig.packages.${system}.rdmacs
    inputs.zen-browser.packages.${system}.default
  ];

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
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    nameservers = [ "10.10.0.1" ];
    enableIPv6 = false;
  };

  # Local caching resolver. Smooths over single-upstream flakiness (Zig's
  # built-in resolver has no retry/fallback, so transient SERVFAILs from
  # 10.10.0.1 break Nix builds otherwise).
  services.resolved = {
    enable = true;
    settings.Resolve.DNSSEC = "false";
  };

  time = {
    timeZone = "America/Chicago";
    hardwareClockInLocalTime = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
