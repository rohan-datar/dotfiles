{
  inputs,
  pkgs,
  ...
}:
{
  olympus.packages = with pkgs; {
    # Give each package a unique name
    maple-mono = maple-mono.NF;
    meslo-lg = nerd-fonts.meslo-lg;
    font-awesome = font-awesome;
    sf-pro = inputs.apple-fonts.packages.${system}.sf-pro;
    sf-pro-nerd = inputs.apple-fonts.packages.${system}.sf-pro-nerd;
    sf-compact = inputs.apple-fonts.packages.${system}.sf-compact;
    sf-compact-nerd = inputs.apple-fonts.packages.${system}.sf-compact-nerd;
    ny = inputs.apple-fonts.packages.${system}.ny;
    ny-nerd = inputs.apple-fonts.packages.${system}.ny-nerd;
  };

  fonts.fontconfig.enable = true;

  stylix.targets.font-packages.enable = true;
  stylix.targets.fontconfig.enable = true;
  stylix.iconTheme = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    light = "Adwaita";
    dark = "Adwaita";
  };
}
