{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # keep automatic monitor config
      "monitor" = [
        ",preferred,auto,auto"
        "HDMI-A-1,preferred,auto,auto"
      ];

      # set alt as the mod key
      "$mainMod" = "Super";

      # Set programs that you use
      "$terminal" = "ghostty";
      "$fileManager" = "nautilus";
      "$menu" = "fuzzel";
      "$browser" = "zen";

      exec-once = [
        "hypridle"
      ];

      xwayland = {
        "force_zero_scaling" = true;
      };

      env = [
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      ];

      cursor = {
        "no_hardware_cursors" = true;
      };

      general = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        border_size = "3";

        resize_on_border = "true";

        "gaps_in" = "4";
        "gaps_out" = "8";

        "layout" = "dwindle";

        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        "allow_tearing" = "false";
      };

      decoration = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more

        rounding = "4";

        blur = {
          enabled = "true";
          size = "3";
          passes = "1";
        };

        # drop_shadow = "yes";
        # shadow_range = "4";
        # shadow_render_power = "3";
        # "col.shadow" = "rgba(1a1a1aee)";
      };

      animations = {
        enabled = "true";

        bezier = "linear, 0.0, 0.0, 1, 1";
        animation = [
          "borderangle, 1, 50, linear, loop"

          "workspaces,1,0.5,default"
          "windows,0,0.1,default"
          "fade,0,0.1,default"
        ];
      };

      dwindle = {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        pseudotile = "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = "yes"; # you probably want this
      };

      misc = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        force_default_wallpaper = "0"; # Set to 0 or 1 to disable the anime mascot wallpapers
      };

      # Example per-device config
      # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
      # device = {
      #   name = "epic-mouse-v1";
      #   sensitivity = "-0.5";
      # };

      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      windowrulev2 = [
        "suppressevent maximize, class:.*" # You'll probably like this.
        "float, title:Volume Control"
      ];
      layerrule = "noanim, wofi";

      # # Sound through pactl
      #       bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +10%
      #       bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -10%
      #       bind = , XF86AudioMut, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle

      # # Brightness through brightnessctl
      #       bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
      #       bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      bind = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause" # the stupid key is called play , but it toggles
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        "$mainMod, return, exec, $terminal"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, B, exec, $browser"
        "$mainMod, space, exec, $menu"
        "$ALT_SHIFT, l, exec, hyprlock"
        "$ALT_SHIFT, R, exec, hyprctl reload"
        # "$SUPER_SHIFT, D, exec, hyprctl keyword monitor eDP-1, disable"
        # "$SUPER_SHIFT, F, exec, hyprctl keyword monitor eDP-1, enable"
        ", Print, exec, hyprshot -m window"
        "shift, Print, exec, hyprshot -m region"
        "$mainMod, P, pseudo, # dwindle"
        "$mainMod, E, togglesplit, # dwindle"
        "$mainMod, F, fullscreen, # dwindle"
        "$mainMod, W, togglegroup, # dwindle"

        # Move focus with mainMod + arrow keys
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Example special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
