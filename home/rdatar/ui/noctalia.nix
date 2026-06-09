{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf config.olympus.aspects.graphical.enable {
    programs.noctalia = {
      enable = true;
      settings = ''
        [audio]
        enable_overdrive = false

        [bar.main]
        background_opacity = 0
        center = [ "clock" ]
        end = [ "screenshot", "group:g1", "group:g2", "volume", "notifications", "session" ]
        margin_ends = 0
        scale = 1.2500000111758709
        start = [ "control-center", "workspaces", "active_window", "media" ]

            [[bar.main.capsule_group]]
            fill = "surface_variant"
            id = "g1"
            members = [ "temp", "cpu", "ram" ]
            opacity = 1.0
            padding = 6.0

            [[bar.main.capsule_group]]
            fill = "surface_variant"
            id = "g2"
            members = [ "network", "bluetooth" ]
            opacity = 1.0
            padding = 6.0

        [[control_center.shortcuts]]
        type = "wifi"

        [[control_center.shortcuts]]
        type = "bluetooth"

        [[control_center.shortcuts]]
        type = "wallpaper"

        [[control_center.shortcuts]]
        type = "caffeine"

        [[control_center.shortcuts]]
        type = "clipboard"

        [[control_center.shortcuts]]
        type = "screen_recorder"

        [desktop_widgets]
        enabled = false
        schema_version = 2
        widget_order = []

            [desktop_widgets.grid]
            cell_size = 16
            major_interval = 4
            visible = true

            [desktop_widgets.widget]

        [dock]
        enabled = false

        [idle]
        behavior_order = [ "lock", "screen-off", "lock-and-suspend" ]

            [idle.behavior.lock]
            action = "lock"
            enabled = true
            timeout = 600

            [idle.behavior.lock-and-suspend]
            action = "lock_and_suspend"
            enabled = true
            timeout = 900

            [idle.behavior.screen-off]
            action = "screen_off"
            enabled = true
            timeout = 660

        [location]
        address = "Madison, WI"
        auto_locate = false
        sunrise = "06:30"
        sunset = "18:30"

        [lockscreen_widgets]
        enabled = false
        schema_version = 2
        widget_order = [ "lockscreen-login-box@HDMI-A-1" ]

            [lockscreen_widgets.grid]
            cell_size = 16
            major_interval = 4
            visible = true

            [lockscreen_widgets.widget."lockscreen-login-box@HDMI-A-1"]
            box_height = 0.0
            box_width = 0.0
            cx = 1280.0
            cy = 1317.0
            output = "HDMI-A-1"
            rotation = 0.0
            type = "login_box"

        [nightlight]
        enabled = true
        force = false
        temperature_day = 6500
        temperature_night = 4000

        [osd]
        background_opacity = 0
        orientation = "vertical"
        position = "center_right"

        [shell]
        avatar_path = "${toString ../assets/HAL-9000-icon.png}"
        clipboard_auto_paste = "off"
        clipboard_enabled = true
        corner_radius_scale = 1
        font_family = "SFPro Nerd Font"
        launch_apps_as_systemd_services = false
        settings_show_advanced = true
        ui_scale = 1.2

            [shell.mpris]
            blacklist = []

            [shell.panel]
            clipboard_placement = "centered"
            control_center_placement = "attached"
            launcher_placement = "centered"
            open_near_click_control_center = true
            session_placement = "centered"
            wallpaper_placement = "centered"

            [[shell.session.actions]]
            action = "lock"
            enabled = true

            [[shell.session.actions]]
            action = "suspend"
            enabled = true

            [[shell.session.actions]]
            action = "reboot"
            enabled = true

            [[shell.session.actions]]
            action = "logout"
            enabled = true

            [[shell.session.actions]]
            action = "shutdown"
            enabled = true

        [theme]
        builtin = "Catppuccin"
        mode = "dark"
        source = "builtin"

            [theme.templates]
            enable_builtin_templates = true

        [wallpaper]
        directory = "/home/rdatar/.local/share/backgrounds"
        edge_smoothness = 0.050000000000000003
        enabled = true
        fill_color = "#000000"
        fill_mode = "crop"
        per_monitor_directories = false
        transition = [ "fade" ]
        transition_duration = 1500

            [wallpaper.automation]
            enabled = true
            interval_seconds = 300
            order = "random"
            recursive = false

            [wallpaper.default]
            path = "/home/rdatar/.local/share/backgrounds/satellite.png"

            [wallpaper.last]
            path = "/home/rdatar/.local/share/backgrounds/satellite.png"

            [wallpaper.monitors.HDMI-A-1]
            path = "/home/rdatar/.local/share/backgrounds/satellite.png"

        [weather]
        enabled = true
        unit = "celsius"

        [widget.active_window]
        capsule_opacity = 0.52000000000000002
        capsule_padding = 4.0
        display = "icon_and_text"
        max_length = 145
        title_scroll = "on_hover"

        [widget.bluetooth]
        show_label = false

        [widget.clock]
        format = "{:%I:%M %p  %a, %b %d}"
        vertical_format = "{:%H %M - %d %m}"

        [widget.control-center]
        capsule = true
        capsule_padding = 4.0
        custom_image = "/home/rdatar/Pictures/NixOS.png"

        [widget.media]
        hide_when_no_media = true
        max_length = 145
        title_scroll = "on_hover"

        [widget.network]
        show_label = false

        [widget.notifications]
        hide_when_no_unread = false

        [widget.volume]
        scroll_step = 5
        show_label = false

        [widget.workspaces]
        display = "id"
        hide_when_empty = true
        max_label_chars = 2
      '';
    };
  };
}
