{
  config,
  inputs,
  options,
  osClass,
  ...
}:
let
  isNixos = osClass == "nixos";
  isGui = isNixos && config.olympus.aspects.graphical.enable;
in
{
  imports = if isNixos then [ inputs.catppuccin.homeModules.catppuccin ] else [ ];

  config = {
    catppuccin = {
      enable = true;
      sources = options.catppuccin.sources.default;

      flavor = "mocha";
      accent = "blue";

      cursors = {
        enable = isGui;
        accent = "dark";
      };

      gtk.icon.enable = isGui;
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
