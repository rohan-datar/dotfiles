{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  config = {
    programs.vicinae = {
      package = pkgs.vicinae.override {
        nodejs = (import ../../../nixos/_packages/nodejs-security.nix { inherit pkgs; }).nodejs_24;
      };
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
            family = "SFPro Nerd Font";
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
        # bluetooth
        nix
        niri
      ];
    };
  };
}
