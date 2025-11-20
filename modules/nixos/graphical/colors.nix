{
  lib,
  config,
  inputs,
  options,
  ...
}:
{
  imports = [ inputs.catppuccin.nixosModules.catppuccin ];

  config = {
    catppuccin = {
      enable = lib.mkDefault config.olympus.aspects.graphical.enable;
      sources = options.catppuccin.sources.default;
      flavor = "mocha";
      accent = "blue";
      cache.enable = true;

      # IFD, easy to vendor
      tty.enable = false;

    };

    console.colors = lib.mkIf config.catppuccin.enable [
      "1e1e2e"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "bac2de"
      "585b70"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "a6adc8"
    ];
  };
}
