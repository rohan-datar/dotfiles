{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    olympus.packages = {
      # Give each package a unique name
      inherit (pkgs) font-awesome;
      inherit (pkgs.maple-mono) NF;
      inherit (pkgs.nerd-fonts) meslo-lg;
      inherit (inputs.apple-fonts.packages.${system})
        sf-pro
        sf-pro-nerd
        sf-compact
        sf-compact-nerd
        ny
        ny-nerd
        ;
    };

    fonts.fontconfig = {
      defaultFonts = {
        monospace = [
          "Maple Mono NF"
          "SFMono Nerd Font"
        ];
        sansSerif = [
          "SFProDisplay Nerd Font"
          "MesloLGS Nerd Font Propo"
        ];
        serif = [
          "NewYork Nerd Font"
          "Liberation Serif"
        ];
        emoji = [
          "Noto Color Emoji"
          "Symbols Nerd Font"
        ];
      };
    };
  };
}
