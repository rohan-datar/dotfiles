{
  pkgs,
  inputs,
  ...
}: {
  stylix = {
    enable = true;
    base16Scheme = "${inputs.tinted-schemes}/base24/catppuccin-mocha.yaml";
    polarity = "dark";
    # fonts = {
    #   serif = {
    #     package = pkgs.dejavu_fonts;
    #     name = "DejaVu Serif";
    #   };

    #   sansSerif = {
    #     package = pkgs.jetbrains-mono;
    #     name = "JetBrains Mono Nerd Font Propo";
    #   };

    #   monospace = {
    #     package = pkgs.maple-mono.NF;
    #     name = "Maple Mono NF";
    #   };

    #   emoji = {
    #     package = pkgs.noto-fonts-emoji;
    #     name = "Noto Color Emoji";
    #   };
    # };

    cursor = {
      pkgs = pkgs.catppuccin-cursors.mochaBlue;
      name = "Catppuccin Mocha Blue";
    };
  };
}
