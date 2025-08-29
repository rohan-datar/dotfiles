{
  inputs,
  pkgs,
  ...
}:
{

  olympus.packages = with pkgs; {
    # Give each package a unique name
    maple-mono = maple-mono.NF;
    inherit (nerd-fonts) meslo-lg;
    inherit font-awesome;
    inherit (inputs.apple-fonts.packages.${system}) sf-pro;
    inherit (inputs.apple-fonts.packages.${system}) sf-pro-nerd;
    inherit (inputs.apple-fonts.packages.${system}) sf-compact;
    inherit (inputs.apple-fonts.packages.${system}) sf-compact-nerd;
    inherit (inputs.apple-fonts.packages.${system}) ny;
    inherit (inputs.apple-fonts.packages.${system}) ny-nerd;
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
