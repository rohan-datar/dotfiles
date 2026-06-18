{
  pkgs,
  inputs,
  ...
}:
let
  name = "Rohans-MacBook";
  # Extract the config name from the flake
  configName = builtins.baseNameOf (builtins.toString ./.);
  inherit (pkgs.stdenv.hostPlatform) system;
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
        openldap
        ;
      emacs = inputs.editorconfig.packages.${system}.rdmacs;
    };

    environment.flakePath = "/Users/rohandatar/nix";

  };

  nix-homebrew.trust.casks = [ "barutsrb/tap/omniwm" ];

  homebrew = {
    enable = true;

    taps = [
      "BarutSRB/tap"
    ];

    brews = [
      "xcode-build-server"
    ];

    casks = [
      "beeper"
      "omnidisksweeper"
      "omniwm"
      # "docker-desktop"
    ];

    # masApps = {
    #   "Xcode" = 497799835;
    # };
  };

  networking = {
    hostName = name;
    localHostName = name;
    computerName = name;
  };

  environment.variables = {
    NIX_CONFIG_NAME = configName;
    LC_ALL = "en_US.UTF-8";
  };

  services.lorri.enable = true;
  services.emacs = {
    enable = true;
    package = inputs.editorconfig.packages.${system}.rdmacs;
  };

  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
