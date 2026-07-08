_: {
  flake.wrappers.niri =
    {
      wlib,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.niri ];

      settings = {
        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
        prefer-no-csd = true;

        screenshot-path = "~/Pictures/screenshots/%Y-%m-%d %H-%M-%S.png";

        hotkey-overlay = {
          hide-not-bound = true;
          skip-at-startup = true;
        };

        window-rules = [
          {
            default-column-width = {
              proportion = 0.5;
            };
          }
          { draw-border-with-background = false; }
          {
            geometry-corner-radius = 12.0;
            clip-to-geometry = true;
          }
        ];

        layout = {
          border.width = 1;
          gaps = 8;
          empty-workspace-above-first = true;
        };

        environment = {
          SHLVL = "0";
          QT_QPA_PLATFORM = "wayland";
          XDG_SESSION_TYPE = "wayland";
          NIXOS_OZONE_WL = "1";
        };

        binds =
          let
            mod = "Super";
          in
          {
            "${mod}+K".focus-window-or-workspace-up = _: { };
            "${mod}+J".focus-window-or-workspace-down = _: { };
            "${mod}+H".focus-column-or-monitor-left = _: { };
            "${mod}+L".focus-column-or-monitor-right = _: { };
            "${mod}+Up".focus-window-up = _: { };
            "${mod}+Down".focus-window-down = _: { };
            "${mod}+Left".focus-column-left = _: { };
            "${mod}+Right".focus-column-right = _: { };

            "${mod}+Shift+K".move-window-up-or-to-workspace-up = _: { };
            "${mod}+Shift+J".move-window-down-or-to-workspace-down = _: { };
            "${mod}+Shift+H".move-column-left-or-to-monitor-left = _: { };
            "${mod}+Shift+L".move-column-right-or-to-monitor-right = _: { };
            "${mod}+Shift+Up".move-window-up = _: { };
            "${mod}+Shift+Down".move-window-down = _: { };
            "${mod}+Shift+Left".move-column-left = _: { };
            "${mod}+Shift+Right".move-column-right = _: { };

            "${mod}+Q".close-window = _: { };
            "${mod}+F".maximize-column = _: { };
            "${mod}+Shift+F".fullscreen-window = _: { };
            "${mod}+Ctrl+F".expand-column-to-available-width = _: { };
            "${mod}+W".toggle-column-tabbed-display = _: { };
            "${mod}+Comma".consume-or-expel-window-left = _: { };
            "${mod}+Period".consume-or-expel-window-right = _: { };
            "${mod}+C".center-column = _: { };
            "${mod}+Shift+C".center-visible-columns = _: { };
            "${mod}+V".toggle-window-floating = _: { };
            "${mod}+Shift+V".switch-focus-between-floating-and-tiling = _: { };

            "${mod}+Equal".set-column-width = "+10%";
            "${mod}+Minus".set-column-width = "-10%";
            "${mod}+Shift+1".set-column-width = "50%";
            "${mod}+Shift+Equal".set-window-height = "+10%";
            "${mod}+Shift+Minus".set-window-height = "-10%";

            "${mod}+Return".spawn = "ghostty";
            "${mod}+B".spawn = "zen";

            "${mod}+Shift+S".screenshot = _: { };
            "${mod}+Shift+Slash".show-hotkey-overlay = _: { };
            "${mod}+Tab".toggle-overview = _: { };
            "Ctrl+Alt+Delete".quit = _: { };

            "${mod}+Space" = _: {
              props.repeat = false;
              content.spawn = [
                "vicinae"
                "toggle"
              ];
            };

            "XF86AudioRaiseVolume".spawn = [
              "noctalia"
              "msg"
              "volume-up"
              "5%"
            ];
            "XF86AudioLowerVolume".spawn = [
              "noctalia"
              "msg"
              "volume-down"
              "5%"
            ];
            "XF86AudioMute".spawn = [
              "noctalia"
              "msg"
              "volume-mute"
            ];
            "XF86MonBrightnessUp".spawn = [
              "noctalia"
              "msg"
              "brightness-up"
              "5%"
            ];
            "XF86MonBrightnessDown".spawn = [
              "noctalia"
              "msg"
              "brightness-down"
              "5%"
            ];
          };

        input.focus-follows-mouse = _: { };
      };
    };
}
