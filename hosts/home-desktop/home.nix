{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
