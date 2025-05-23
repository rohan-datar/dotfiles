# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./system.nix
    ../../modules/shared
    # ./overlays.nix
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  # Set zsh as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    kitty
    busybox
    bitwarden-desktop
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
    xspim
    nautilus
    # jdk
    zulu
  ];
  age.secrets.smbcredentials.file = ../../secrets/smbcredentials.age;
  fileSystems."/mnt/data-share" = {
    device = "//10.10.1.10/data-share";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.age.secrets.smbcredentials.path},uid=1000,gid=3000"];
  };

  environment.sessionVariables = {
    TERMINAL = "ghostty";
    DEFAULT_BROWSER = "zen";
    NIXOS_OZONE_WL = "1";
  };

  environment.variables.EDITOR = "nvim";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
