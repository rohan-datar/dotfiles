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
  config = mkIf config.olympus.aspects.graphical.enable {
    olympus.packages = {
      inherit (pkgs)
        blueman
        hyprshot
        hypridle
        pavucontrol
        brightnessctl
        fuzzel
        ;
      noctalia = inputs.noctalia.packages.${system}.default;
    };
  };

}
