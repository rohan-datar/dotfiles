{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../common
    ./aerospace.nix
  ];

  home.packages = [pkgs.sketchybar-app-font];

  programs.nh.flake = "/Users/rohandatar/nix";

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rohandatar";
  home.homeDirectory = "/Users/rohandatar";
}
