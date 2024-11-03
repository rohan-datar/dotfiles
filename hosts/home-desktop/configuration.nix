# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}: let
  catppuccinHome = inputs.catppuccin.homeManagerModules.catppuccin;
in {
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

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};
    users = {
      rdatar = {
        imports = [
          ./home.nix
          catppuccinHome
        ];
      };
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Set zsh as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    busybox
    bitwarden-desktop
    cargo
    clang
    gcc
    nodejs
    wezterm
    kitty
    lua
    gnumake
    gnome-tweaks
    cacert
    home-manager
    wl-clipboard
    ungoogled-chromium
    obsidian-wayland
    inputs.zen-browser.packages."${system}".specific
    gnomeExtensions.dash-to-dock
    libnotify
    glib
    mako
    copyq
  ];

  fonts.packages = with pkgs; [
    maple-mono-NF
    (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono"];})
  ];

  environment.sessionVariables = {
    DEFAULT_BROWSER = "zen";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  environment.variables.EDITOR = "neovim";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
