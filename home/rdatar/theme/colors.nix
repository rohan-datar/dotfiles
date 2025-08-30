{
  config,
  inputs,
  options,
  osClass,
  ...
}:
let
  isGui = osClass == "nixos" && config.olympus.aspects.graphical.enable;
in
{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

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
    };
  };
}
