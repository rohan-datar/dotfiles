{
  pkgs,
  config,
  lib,
  ...
}:
let
  pwaBrowser = pkgs.lib.getExe pkgs.google-chrome;
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    # set up PWAs
    xdg.desktopEntries.appleMusic = {
      name = "Apple Music";
      exec = "${pwaBrowser} --app=https://music.apple.com/in/";
      icon = ../assets/icons8-apple-music-480.png;
    };
  };
}
