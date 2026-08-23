{
  pkgs,
  inputs,
  self,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [
    ./user.nix
    self.modules.darwin.rohandatar
    self.modules.darwin.graphical
  ];

  environment.pathsToLink = [ "/libexec" ];

  homebrew = {
    enable = true;

    brews = [
      "xcode-build-server"
    ];

    casks = [
      "beeper"
      "omnidisksweeper"
    ];
  };

  networking = {
    hostName = "Rohans-MacBook";
    localHostName = "Rohans-MacBook";
    computerName = "Rohans-MacBook";
  };

  environment.variables = {
    LC_ALL = "en_US.UTF-8";
    FLAKE = "/Users/rohandatar/nix";
    NH_FLAKE = "/Users/rohandatar/nix";
  };

  # Vicinae launcher: keep the server daemon running at login
  launchd.agents.vicinae = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.vicinae}/bin/vicinae"
        "server"
      ];
      RunAtLoad = true;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ProcessType = "Interactive";
    };
  };

  services.lorri.enable = true;
  services.emacs = {
    enable = true;
    package = inputs.editorconfig.packages.${system}.rdmacs;
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      mkalias
      iina
      swiftlint
      swift-format
      xcbeautify
      vicinae
      appcleaner
      openldap
      container
      ;
    emacs = inputs.editorconfig.packages.${system}.rdmacs;
  };

  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
