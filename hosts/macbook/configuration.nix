{ pkgs, config, ... }:

{
  imports = [
    ../../modules/shared
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.mkalias
    pkgs.iina
    pkgs.pngpaste
  ];

  homebrew = {
    enable = true;
    brews = [
      "tpm"
      "rust"
      "node"
      "mas"
      "openjdk@21"
    ];

    casks = [
      "aerospace"
      "appcleaner"
      "beeper"
      "chromium"
      "discord"
      "docker"
      "firefox"
      "obsidian"
      "omnidisksweeper"
      "the-unarchiver"
      "thunderbird"
      "wezterm"
      "zen-browser"
    ];

    masApps = {
      "Amphetamine" = 937984704;
      "Bitwarden" = 1352778147;
      "CopyClip" = 595191960;
      "Hidden Bar" = 1452453066;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Tailscale" = 1475387142;
      "Xcode" = 497799835;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  fonts.packages = [
    pkgs.maple-mono-NF
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];


  # script to force nix to make aliases for apps that can be indexed by MacOS
  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = "/Applications";
      };
    in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  system.defaults = {
    loginwindow.GuestEnabled = false;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.KeyRepeat = 2;

    # Expand save panel by default
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

    # Expand print panel by default
    NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
    NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;

    # Enable subpixel font rendering on non-Apple LCDs
    # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
    NSGlobalDomain.AppleFontSmoothing = 1;

    # Show hidden files by default
    NSGlobalDomain.AppleShowAllFiles = true;
    NSGlobalDomain.AppleShowAllExtensions = true;

    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
    finder.FXPreferredViewStyle = "Nlsv";

    # Finder: show path bar
    # finder.ShowPathBar = true;

    # Keep folders on top when sorting by name
    finder._FXSortFoldersFirst = true;

    # When performing a search, search the current folder by default
    finder.FXDefaultSearchScope = "SCcf";

    # Disable the warning when changing a file extension
    finder.FXEnableExtensionChangeWarning = false;

    # Disable the “Are you sure you want to open this application?” dialog
    LaunchServices.LSQuarantine = false;

    # Save screenshots to the desktop
    screencapture.location = "~/Desktop/Screenshots";

  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;


  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
