{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ./system.nix
    ../../modules/shared
    inputs.home-manager.darwinModules.home-manager
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    mkalias
    iina
    pngpaste
    aerospace
    swiftlint
    swift-format
    xcbeautify
    rubyPackages.xcodeproj
  ];

  homebrew = {
    enable = true;
    brews = [
      "rust"
      "node"
      "mas"
      "openjdk@21"
      "switchaudio-osx"
      "swift"
      "xcode-build-server"
      "pkl"
    ];

    casks = [
      "appcleaner"
      "chromium"
      "discord"
      "firefox"
      "omnidisksweeper"
      "zen"
      "ghostty"
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "CopyClip" = 595191960;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Xcode" = 497799835;
      "WireGuard" = 1451685025;
      "Beeper" = 6499013100;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;

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
