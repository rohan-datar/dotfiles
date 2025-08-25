{
  pkgs,
  inputs,
}:
let
  name = "Rohans-MacBook";
in
{
  imports = [ ./user.nix ];

  olympus = {
    aspects.graphical.enable = true;

    packages = {
      inherit (pkgs)
        mkalias
        iina
        swiftlint
        swift-format
        xcbeautify
        raycast
        appcleaner
        ;

      environment.flakePath = "/home/rdatar/nix";

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
      hostName = name;
      localHostName = name;
      computerName = name;
    };

    # $ darwin-rebuild changelog
    system.stateVersion = 5;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
