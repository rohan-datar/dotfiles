{
  pkgs,
  config,
  inputs,
  macbook,
  ...
}:
{
  imports = [
    ./system.nix
    ../../modules/shared
    inputs.home-manager.darwinModules.home-manager
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  olympus.packages = {
    inherit (pkgs)
      mkalias
      iina
      swiftlint
      swift-format
      xcbeautify
      raycast
      appcleaner
      ;
  };

  homebrew = {
    enable = true;
    brews = [
      "openjdk@21"
      "xcode-build-server"
    ];

    casks = [
      "omnidisksweeper"
      "beeper"
    ];

    masApps = {
      "Xcode" = 497799835;
    };
  };

  networking = {
    hostName = macbook;
    localHostName = macbook;
    computerName = macbook;
  };

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
