{
  config,
  inputs,
  options,
  pkgs,
  ...
}:
let
  isNixos = pkgs.stdenv.hostPlatform.isLinux;
  isGui = isNixos;
in
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  config = {
    catppuccin = {
      autoEnable = true;
      enable = true;
      sources = options.catppuccin.sources.default;

      flavor = "mocha";
      accent = "blue";

      cursors = {
        enable = isGui;
        accent = "dark";
      };

      gtk.icon.enable = isGui;
      zed.icons.enable = isGui;
      firefox.enable = isGui;
      kvantum.enable = isGui;
      # doesn't build on macos
      starship.enable = false;
      waybar.enable = false;
      eza.enable = false;
      fzf.enable = false;
    };
  };
}
