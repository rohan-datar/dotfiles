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
        sliver_width = 2;
        animation_speed = 4;
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

        # resize
        window_grow = "cmd - equal";
        window_shrink = "cmd - minus";

        # full-width (niri mod+F maximize-column)
        window_fullwidth = "cmd + shift - f";
        window_resize = "cmd - r";

        # center (niri mod+C center-column)
        window_center = "cmd + alt - c";

        # stack / unstack (niri mod+Comma / mod+Period consume-or-expel)
        window_stack = "cmd - comma";
        window_unstack = "cmd - period";

        # floating
        window_togglefloatlayer = "cmd + alt - v";

        # quit (niri Ctrl+Alt+Delete)
        quit = "ctrl + alt - delete";

        # workspaces
        window_swap_north = "cmd + shift - uparrow";
        window_virtualmove_north = "cmd + shift - k";
        window_swap_south = "cmd + shift - downarrow";
        window_virtualmove_south = "cmd + shift - j";

        window_virtualnum_1 = "cmd - 1";
        window_virtualmovenum_1 = "cmd + shift - 1";
        window_virtualnum_2 = "cmd - 2";
        window_virtualmovenum_2 = "cmd + shift - 2";
        window_virtualnum_3 = "cmd - 3";
        window_virtualmovenum_3 = "cmd + shift - 3";
        window_virtualnum_4 = "cmd - 4";
        window_virtualmovenum_4 = "cmd + shift - 4";
        window_virtualnum_5 = "cmd - 5";
        window_virtualmovenum_5 = "cmd + shift - 5";
        window_virtualnum_6 = "cmd - 6";
        window_virtualmovenum_6 = "cmd + shift - 6";
        window_virtualnum_7 = "cmd - 7";
        window_virtualmovenum_7 = "cmd + shift - 7";
        window_virtualnum_8 = "cmd - 8";
        window_virtualmovenum_8 = "cmd + shift - 8";
        window_virtualnum_9 = "cmd - 9";
        window_virtualmovenum_9 = "cmd + shift - 9";
      };
    };
  };
}
