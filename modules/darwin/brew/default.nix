{
  inputs,
  ...
}:
{
  imports = [
    inputs.homebrew.darwinModules.nix-homebrew
    ./environment.nix
  ];

  config = {
    nix-homebrew = {
      enable = true;

      # we need a user to install the packages for
      user = "rohandatar"; # TODO: find a way to customize this per host

      enableRosetta = true;

      autoMigrate = true;
    };

    # default brews
    homebrew = {
      enable = true;
      brews = [
        "mas"
        "swift"
      ];

      casks = [
        "zen"
        "ghostty"
      ];

      masApps = {
        "Keynote" = 409183694;
        "Numbers" = 409203825;
        "Pages" = 409201541;
      };
      onActivation.cleanup = "zap";
      onActivation.autoUpdate = true;
      onActivation.upgrade = true;
    };
  };
}
