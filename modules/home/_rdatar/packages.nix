{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  config = {
    home.packages = [
      pkgs.blueman
      pkgs.hyprshot
      pkgs.hypridle
      pkgs.pavucontrol
      pkgs.brightnessctl
      pkgs.fuzzel
      inputs.noctalia.packages.${system}.default
    ];
  };
}
