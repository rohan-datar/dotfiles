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
      ];

      # masApps = {
      #   "Keynote: Design Presentations" = 361285480;
      #   "Numbers: Make Spreadsheets" = 361304891;
      #   "Pages: Create Documents" = 361309726;
      # };
      onActivation.cleanup = "zap";
      onActivation.autoUpdate = true;
      onActivation.upgrade = true;
    };
  };
}
