{
  config,
  lib,
  ...
}:
let
  mod = "Super";
  inherit (lib) mkIf splitString;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    programs.niri = {
      settings = {
        prefer-no-csd = true;

        screenshot-path = "~/Pictures/screenshots/%Y-%m-%d %H-%M-%S.png";

        window-rules = [
          {
            default-column-width = {
              proportion = 0.5;
            };
          }
          { draw-border-with-background = false; }
          {
            geometry-corner-radius =
              let
                r = 0.0;
              in
              {
                top-left = r;
                top-right = r;
                bottom-left = r;
                bottom-right = r;
              };
            clip-to-geometry = true;
          }
        ];

        layout = {
          # always-center-single-column = true;
          border.width = 1;
          gaps = 8;
          empty-workspace-above-first = true;
        };

        environment = {
          QT_QPA_PLATFORM = "wayland";
          XDG_SESSION_TYPE = "wayland";
        };

        binds =
          with config.lib.niri.actions;
          let
            noctalia =
              cmd:
              [
                "noctalia-shell"
                "ipc"
                "call"
              ]
              ++ (splitString " " cmd);
          in
          {
            # basic controls
            "${mod}+K".action = focus-window-or-workspace-up;
            "${mod}+J".action = focus-window-or-workspace-down;
            "${mod}+H".action = focus-column-or-monitor-left;
            "${mod}+L".action = focus-column-or-monitor-right;
            "${mod}+Up".action = focus-window-up;
            "${mod}+Down".action = focus-window-down;
            "${mod}+Left".action = focus-column-left;
            "${mod}+Right".action = focus-column-right;
            "${mod}+Shift+K".action = move-window-up-or-to-workspace-up;
            "${mod}+Shift+J".action = move-window-down-or-to-workspace-down;
            "${mod}+Shift+H".action = move-column-left-or-to-monitor-left;
            "${mod}+Shift+L".action = move-column-right-or-to-monitor-right;
            "${mod}+Shift+Up".action = move-window-up;
            "${mod}+Shift+Down".action = move-window-down;
            "${mod}+Shift+Left".action = move-column-left;
            "${mod}+Shift+Right".action = move-column-right;

            "${mod}+Q".action = close-window;
            "${mod}+F".action = maximize-column;
            "${mod}+Shift+F".action = fullscreen-window;
            "${mod}+Ctrl+F".action = expand-column-to-available-width;
            "${mod}+W".action = toggle-column-tabbed-display;
            "${mod}+Comma".action = consume-or-expel-window-left;
            "${mod}+Period".action = consume-or-expel-window-right;
            "${mod}+C".action = center-column;
            "${mod}+Shift+C".action = center-visible-columns;
            "${mod}+V".action = toggle-window-floating;
            "${mod}+Shift+V".action = switch-focus-between-floating-and-tiling;

            # resize things
            "${mod}+Equal".action = set-column-width "+10%";
            "${mod}+Minus".action = set-column-width "-10%";
            "${mod}+Shift+1".action = set-column-width "50%";
            "${mod}+Shift+Equal".action = set-window-height "+10%";
            "${mod}+Shift+Minus".action = set-window-height "-10%";

            "${mod}+Return".action.spawn = "ghostty";
            "${mod}+B".action.spawn = "zen";

            "${mod}+Shift+S".action.screenshot = { };
            "${mod}+Shift+Slash".action = show-hotkey-overlay;
            "${mod}+Tab".action = toggle-overview;
            "Ctrl+Alt+Delete".action = quit;

            "${mod}+Space".action.spawn = noctalia "launcher toggle";
            "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
            "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
            "XF86AudioMute".action.spawn = noctalia "volume muteOutput";

            "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";

            "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
          };

        input.focus-follows-mouse.enable = true;
      };
    };
  };
}
