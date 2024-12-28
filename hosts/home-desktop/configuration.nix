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
    inputs.home-manager.nixosModules.home-manager
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Set zsh as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    kitty
    busybox
    cider
    bitwarden-desktop
    cargo
    clang
    gcc
    nodejs
    lua
    gnumake
    gnome-tweaks
    gnome-terminal
    cacert
    wl-clipboard
    ungoogled-chromium
    obsidian
    inputs.zen-browser.packages."${system}".specific
    inputs.ghostty.packages.x86_64-linux.default
    libnotify
    glib
    copyq
    swift
  ];

  dmraid = prev.dmraid.overrideAttrs (oA: {
    patches =
      oA.patches
      ++ [
        (prev.fetchpatch2 {
          url = "https://raw.githubusercontent.com/NixOS/nixpkgs/f298cd74e67a841289fd0f10ef4ee85cfbbc4133/pkgs/os-specific/linux/dmraid/fix-dmevent_tool.patch";
          hash = "sha256-MmAzpdM3UNRdOk66CnBxVGgbJTzJK43E8EVBfuCFppc=";
        })
      ];
  });

  environment.sessionVariables = {
    TERMINAL = "kitty";
    DEFAULT_BROWSER = "zen";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  environment.variables.EDITOR = "neovim";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
