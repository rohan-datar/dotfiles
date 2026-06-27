# Paneru configuration for macOS, mirroring home/rdatar/ui/niri.nix on Linux.
#
# `Super` from the niri config maps to `cmd` here (matches the aerospace layout
# this host used previously). Key names follow paneru's CONFIGURATION.md, e.g.
# `uparrow`/`downarrow`/`leftarrow`/`rightarrow`, `equal`, `minus`, `comma`,
# `period`, `delete`.
#
# Notable niri binds with no paneru equivalent (left to macOS / unavailable):
#   - mod+Q close-window        -> use macOS cmd-w
#   - mod+Shift+F fullscreen    -> no paneru action
#   - mod+Ctrl+F expand-column  -> no paneru action
#   - mod+W tabbed column       -> no paneru action
#   - mod+Shift+C center-all    -> no paneru action
#   - mod+Shift+1 width "50%"   -> 0.5 is in preset_column_widths; cycle via window_grow
#   - mod+Shift+Equal/Minus     -> paneru columns are horizontal strips; no vertical resize
#   - mod+Return / mod+B        -> paneru bindings have no spawn action
#   - mod+Shift+S screenshot    -> no paneru action
#   - mod+Shift+Slash hotkeys   -> no paneru action
#   - mod+Tab overview          -> no paneru action
#   - mod+Space (vicinae)       -> no spawn action
#   - media keys (volume/brightness) -> no spawn action
{
  services.paneru = {
    enable = true;

    settings = {
      options = {
        # mirrors niri: input.focus-follows-mouse.enable
        focus_follows_mouse = true;
        mouse_follows_focus = true;
        # 0.5 mirrors niri's default-column-width proportion; rest are paneru defaults
        preset_column_widths = [
          0.25
          0.33
          0.5
          0.66
          0.75
        ];
      };

      # Closest analogue to niri layout.gaps (screen-edge padding; paneru has
      # no inter-window gaps concept).
      padding = {
        top = 8;
        bottom = 8;
        left = 8;
        right = 8;
      };

      # mirrors niri: layout.border.width = 1 and geometry-corner-radius = 12
      decorations.active.border = {
        enabled = true;
        width = 1.0;
        radius = 12.0;
      };

      bindings = {
        # focus (niri mod+h/j/k/l and mod+arrows)
        window_focus_west = [
          "cmd - h"
          "cmd - leftarrow"
        ];
        window_focus_east = [
          "cmd - l"
          "cmd - rightarrow"
        ];
        window_focus_north = "cmd - uparrow";
        window_virtual_north = "cmd - k";
        window_focus_south = "cmd - downarrow";
        window_virtual_south = "cmd - j";

        # swap (niri mod+shift+h/j/k/l and mod+shift+arrows)
        window_swap_west = [
          "cmd + shift - h"
          "cmd + shift - leftarrow"
        ];
        window_swap_east = [
          "cmd + shift - l"
          "cmd + shift - rightarrow"
        ];
        window_swap_north = "cmd + shift - uparrow";
        window_virtualmove_north = "cmd + shift - k";
        window_swap_south = "cmd + shift - downarrow";
        window_virtualmove_south = "cmd + shift - j";

        # resize
        window_grow = "cmd - equal";
        window_shrink = "cmd - minus";

        # full-width (niri mod+F maximize-column)
        window_fullwidth = "cmd + shift - f";
        window_resize = "cmd - r";

        # center (niri mod+C center-column)
        window_center = "cmd - c";

        # stack / unstack (niri mod+Comma / mod+Period consume-or-expel)
        window_stack = "cmd - comma";
        window_unstack = "cmd - period";

        # floating
        window_togglefloatlayer = "cmd + alt - v";

        # quit (niri Ctrl+Alt+Delete)
        quit = "ctrl + alt - delete";
      };
    };
  };
}
