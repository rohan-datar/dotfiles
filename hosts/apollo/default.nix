{
  pkgs,
  ...
}:
let
  name = "Rohans-MacBook";
  # Extract the config name from the flake
  configName = builtins.baseNameOf (builtins.toString ./.);
in
{
  imports = [ ./user.nix ];

  olympus = {
    aspects.graphical.enable = true;

    system.users = [ "rohandatar" ];

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
    };

    environment.flakePath = "/Users/rohandatar/nix";

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
      "docker"
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

  environment.variables.NIX_CONFIG_NAME = configName;

  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
