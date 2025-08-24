{
  inputs,
  pkgs,
  ...
}:
{

  olympus.packages = with pkgs; [
    maple-mono.NF
    nerd-fonts.meslo-lg
    font-awesome
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-compact
    inputs.apple-fonts.packages.${pkgs.system}.sf-compact-nerd
    inputs.apple-fonts.packages.${pkgs.system}.ny
    inputs.apple-fonts.packages.${pkgs.system}.ny-nerd
  ];

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
