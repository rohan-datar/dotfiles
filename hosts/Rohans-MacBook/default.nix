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
    self.modules.darwin.pallas-access # albedo VM may SSH in as rohandatar (owner, 2026-11-22)
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
      "windows-app"
      "vorssaint"
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

  # Remote Login for the albedo VM (and the owner): keys only, never passwords.
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
    '';
  };

  services.lorri.enable = true;
  services.emacs = {
    enable = true;
    package = inputs.editorconfig.packages.${system}.rdmacs;
  };

  services.netbird.enable = true;

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      mkalias
      iina
      vicinae
      appcleaner
      container
      ;
    emacs = inputs.editorconfig.packages.${system}.rdmacs;
    texlive = inputs.editorconfig.packages.${system}.texliveCombined;
  };

  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
