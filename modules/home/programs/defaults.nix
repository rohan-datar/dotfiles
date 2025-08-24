{
  lib,
  osClass,
  ...
}: let
  inherit (lib) mkOption mapAttrs;
  inherit (lib.types) enum nullOr str;

  mkDefault = name: args: mkOption ({description = "default ${name} for the system";} // args);
in {
  options.olympus.programs.defaults = mapAttrs mkDefault {
    shell = {
      type = enum [
        "bash"
        "zsh"
        "fish"
      ];
      default =
        if (osClass == "nixos")
        then "bash"
        else "zsh";
    };

    terminal = {
      type = enum [
        "ghostty"
        "alacritty"
        "ghostty"
        "kitty"
        "wezterm"
      ];
      default = "ghostty";
    };

    fileManager = {
      type = enum [
        "dolphin"
        "nemo"
        "nautilus"
      ];
      default = "nautilus";
    };

    browser = {
      type = enum [
        "firefox"
        "chromium"
        "floorp"
        "zen"
      ];
      default = "zen";
    };

    editor = {
      type = enum [
        "nvim"
        "vscode"
        "emacs"
      ];
      default = "nvim";
    };

    pager = {
      type = str;
      default = "less -FR";
    };

    manpager = {
      type = str;
      default = "nvim +Man!";
    };

    launcher = {
      type = nullOr (enum [
        "wofi"
        "fuzzel"
      ]);
      default = "fuzzel";
    };

    bar = {
      type = nullOr (enum [
        "waybar"
        "quickshell"
        "hyprpanel"
      ]);
      default = "hyprpanel";
    };

    screenLocker = {
      type = nullOr (enum [
        "swaylock"
        "gtklock"
        "hyprlock"
      ]);
      default = "hyprlock";
      description = ''
        The lockscreen module to be loaded by home-manager.
      '';
    };
  };
}
