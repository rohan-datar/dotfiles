{
  pkgs,
  inputs,
  ...
}:
let
  pwaBrowser = pkgs.lib.getExe pkgs.google-chrome;
in
{
  imports = [
    ../../common
    ./hypr
  ];

  programs.nh.flake = "/home/rdatar/nix";

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
