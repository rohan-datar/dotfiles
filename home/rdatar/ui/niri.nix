{
  config,
  lib,
  ...
}:
let
  mod = "Super";
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    programs.niri = {
      settings = {
        window-rules = [
          { draw-border-with-background = false; }
        ];

        layout = {
          border.width = 1;
          gaps = 0;
          empty-workspace-above-first = true;
        };

        environment = {
          QT_QPA_PLATFORM = "wayland";
          XDG_SESSION_TYPE = "wayland";
        };

        binds = with config.lib.niri.actions; {
          # basic controls
          "${mod}+K".action = focus-window-or-workspace-up;
          "${mod}+J".action = focus-window-or-workspace-down;
          "${mod}+H".action = focus-column-or-monitor-left;
          "${mod}+L".action = focus-column-or-monitor-right;
          "${mod}+Shift+K".action = move-window-up-or-to-workspace-up;
          "${mod}+Shift+J".action = move-window-down-or-to-workspace-down;
          "${mod}+Shift+H".action = move-column-left-or-to-monitor-left;
          "${mod}+Shift+L".action = move-column-right-or-to-monitor-right;

          "${mod}+Q".action = close-window;
          "${mod}+F".action = maximize-column;
          "${mod}+Shift+F".action = fullscreen-window;
          "${mod}+W".action = toggle-column-tabbed-display;
          "${mod}+Comma".action = consume-or-expel-window-left;
          "${mod}+Period".action = consume-or-expel-window-right;

          # resize things
          "${mod}+Equal".action = set-column-width "+10%";
          "${mod}+Minus".action = set-column-width "-10%";
          "${mod}+Shift+1".action = set-column-width "50%";
          "${mod}+Shift+Equal".action = set-window-height "+10%";
          "${mod}+Shift+Minus".action = set-window-height "-10%";

          "${mod}+Space".action.spawn = [
            "noctalia-shell"
            "ipc"
            "call"
            "launcher"
            "toggle"
          ];

          "${mod}+Return".action.spawn = "ghostty";
          "${mod}+B".action.spawn = "zen";

          "XF86AudioRaiseVolume".action.spawn = [
            "noctalia-shell"
            "ipc"
            "call"
            "volume"
            "increase"
          ];
          "XF86AudioLowerVolume".action.spawn = [
            "noctalia-shell"
            "ipc"
            "call"
            "volume"
            "decrease"
          ];
          "XF86AudioMute".action.spawn = [
            "noctalia-shell"
            "ipc"
            "call"
            "volume"
            "muteOutput"
          ];

          "XF86MonBrightnessUp".action.spawn = [
            "noctalia-shell"
            "ipc"
            "call"
            "brightness"
            "increase"
          ];

          "XF86MonBrightnessDown".action.spawn = [
            "noctalia-shell"
            "ipc"
            "call"
            "brightness"
            "decrease"
          ];
        };

        input.focus-follows-mouse.enable = true;
      };
    };
  };
}
