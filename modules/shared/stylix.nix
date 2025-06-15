{
  pkgs,
  inputs,
  lib,
  ...
}: {
  stylix = {
    enable = true;
    base16Scheme = "${inputs.tinted-schemes}/base24/catppuccin-mocha.yaml";
    polarity = "dark";
    fonts = {
      sansSerif = stylix.fonts.serif = config.stylix.fonts.sansSerif;

      serif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
        name = "SFProDisplay Nerd Font";
      };

      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };

    opacity = let
      default_opacity = 0.85;
    in {
      desktop = default_opacity;
      terminal = default_opacity;
    };
  };
}
