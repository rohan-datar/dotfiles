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
  config = {
    home.packages = [
      pkgs.font-awesome
      pkgs.maple-mono.NF
      pkgs.nerd-fonts.meslo-lg
      inputs.apple-fonts.packages.${system}.sf-pro
      inputs.apple-fonts.packages.${system}.sf-pro-nerd
      inputs.apple-fonts.packages.${system}.sf-compact
      inputs.apple-fonts.packages.${system}.sf-compact-nerd
      inputs.apple-fonts.packages.${system}.ny
      inputs.apple-fonts.packages.${system}.ny-nerd
    ];

    fonts.fontconfig = {
      defaultFonts = {
        monospace = [
          "Maple Mono NF"
          "JetBrainsMono Nerd Font"
        ];
        sansSerif = [
          "SFPro Nerd Font"
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
