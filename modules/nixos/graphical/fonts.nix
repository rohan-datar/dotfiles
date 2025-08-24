{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: let
  cfg = config.olympus.aspects;
in {
  config = lib.mkIf cfg.graphical.enable {
    stylix.fonts = {
      serif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.ny-nerd;
        name = "SFProDisplay Nerd Font";
      };

      sansSerif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
        name = "SFProDisplay Nerd Font";
      };

      monospace = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd;
        name = "SFMono Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes.popups = 14;
    };
  };
}
