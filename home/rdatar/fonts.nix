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

}
