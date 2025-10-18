{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    programs.hyprlock = {
      enable = true;

      settings = {
        # GENERAL
        general = {
          disable_loading_bar = false;
          hide_cursor = false;
        };

        # BACKGROUND
        background = {
          path = "~/.local/share/backgrounds/Hero_NixOS.png";
          blur_passes = 2;
        };

        label = [
          # TIME
          {
            text = ''cmd[update:30000] echo "$(date +"%R")"'';
            color = "$text";
            font_size = 90;
            font_family = "$font";
            position = "-30, 0";
            halign = "right";
            valign = "top";
          }

          # DATE
          {
            text = ''cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"'';
            color = "$text";
            font_size = 25;
            font_family = "$font";
            position = "-30, -150";
            halign = "right";
            valign = "top";
          }
        ];
      };
    };
  };
}
