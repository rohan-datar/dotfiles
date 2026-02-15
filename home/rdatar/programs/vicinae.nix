{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  config = lib.mkIf config.olympus.aspects.graphical.enable {
    services.vicinae = {
      package = pkgs.vicinae;
      enable = true;
      systemd = {
        enable = true;
        autoStart = true;
      };
      settings = {
        close_on_focus_loss = true;
        keybinding = "emacs";
        font = {
          normal = {
            family = "SFProDisplay Nerd Font";
            size = 11;
          };
        };
        theme = {
          dark = {
            name = "catppuccin-mocha";
            icon_theme = "Catppuccin Mocha Dark";
          };
        };
        launcher_window.opacity = 0.9;
      };
      extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
        bluetooth
        nix
        niri
      ];
    };
  };
}
