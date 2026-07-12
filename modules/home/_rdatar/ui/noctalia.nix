{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = {
        audio.enable_overdrive = false;

        bar.main = {
          background_opacity = 0;
          center = [ "clock" ];
          end = [
            "screenshot"
            "group:g1"
            "group:g2"
            "volume"
            "notifications"
            "session"
          ];
          margin_ends = 0;
          scale = 1.2500000111758709;
          start = [
            "control-center"
            "workspaces"
            "active_window"
            "media"
          ];
          capsule_group = [
            {
              fill = "surface_variant";
              id = "g1";
              members = [
                "temp"
                "cpu"
                "ram"
              ];
              opacity = 1.0;
              padding = 6.0;
            }
            {
              fill = "surface_variant";
              id = "g2";
              members = [
                "network"
                "bluetooth"
              ];
              opacity = 1.0;
              padding = 6.0;
            }
          ];
        };

        control_center.shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "wallpaper"; }
          { type = "caffeine"; }
          { type = "clipboard"; }
          { type = "screen_recorder"; }
        ];

        desktop_widgets = {
          enabled = false;
          schema_version = 2;
          widget_order = [ ];
          grid = {
            cell_size = 16;
            major_interval = 4;
            visible = true;
          };
          widget = { };
        };

        dock.enabled = false;

        idle = {
          behavior_order = [
            "lock"
            "screen-off"
            "lock-and-suspend"
          ];
          behavior = {
            lock = {
              action = "lock";
              enabled = true;
              timeout = 600;
            };
            "lock-and-suspend" = {
              action = "lock_and_suspend";
              enabled = true;
              timeout = 900;
            };
            "screen-off" = {
              action = "screen_off";
              enabled = true;
              timeout = 660;
            };
          };
        };

        location = {
          address = "Madison, WI";
          auto_locate = false;
          sunrise = "06:30";
          sunset = "18:30";
        };

        lockscreen_widgets = {
          enabled = false;
          schema_version = 2;
          widget_order = [ "lockscreen-login-box@DP-3" ];
          grid = {
            cell_size = 16;
            major_interval = 4;
            visible = true;
          };
          widget."lockscreen-login-box@DP-3" = {
            box_height = 0.0;
            box_width = 0.0;
            cx = 1280.0;
            cy = 1317.0;
            output = "DP-3";
            rotation = 0.0;
            type = "login_box";
          };
        };

        nightlight = {
          enabled = true;
          force = false;
          temperature_day = 6500;
          temperature_night = 4000;
        };

        osd = {
          background_opacity = 0;
          orientation = "vertical";
          position_vertical = "center_right";
        };

        shell = {
          avatar_path = toString ../assets/HAL-9000-icon.png;
          clipboard_auto_paste = "off";
          clipboard_enabled = true;
          corner_radius_scale = 1;
          font_family = "SFPro Nerd Font";
          # run0 (the default escalator) cannot ask for a password when
          # launched from the shell GUI; pkexec goes through the polkit agent
          greeter_sync.privilege_command = "pkexec";
          launch_apps_as_systemd_services = true;
          polkit_agent = true;
          settings_show_advanced = true;
          ui_scale = 1.2;
          mpris.blacklist = [ ];
          panel = {
            clipboard_placement = "centered";
            control_center_placement = "attached";
            launcher_placement = "centered";
            open_near_click_control_center = true;
            session_placement = "centered";
            wallpaper_placement = "centered";
          };
          session.actions = [
            {
              action = "lock";
              enabled = true;
            }
            {
              action = "suspend";
              enabled = true;
            }
            {
              action = "reboot";
              enabled = true;
            }
            {
              action = "logout";
              enabled = true;
            }
            {
              action = "shutdown";
              enabled = true;
            }
          ];
        };

        theme = {
          builtin = "Catppuccin";
          mode = "dark";
          source = "builtin";
          templates.enable_builtin_templates = true;
        };

        wallpaper = {
          directory = "/home/rdatar/.local/share/backgrounds";
          edge_smoothness = 0.050000000000000003;
          enabled = true;
          fill_color = "#000000";
          fill_mode = "crop";
          per_monitor_directories = false;
          transition = [ "fade" ];
          transition_duration = 1500;
          automation = {
            enabled = true;
            interval_seconds = 300;
            order = "random";
            recursive = false;
          };
          default.path = "/home/rdatar/.local/share/backgrounds/satellite.png";
          last.path = "/home/rdatar/.local/share/backgrounds/satellite.png";
          monitors."DP-3".path = "/home/rdatar/.local/share/backgrounds/satellite.png";
        };

        weather = {
          enabled = true;
          unit = "celsius";
        };

        widget = {
          active_window = {
            capsule_opacity = 0.52;
            capsule_padding = 4.0;
            display = "icon_and_text";
            max_length = 145;
            title_scroll = "on_hover";
          };
          bluetooth.show_label = false;
          clock = {
            format = "{:%I:%M %p  %a, %b %d}";
            vertical_format = "{:%H %M - %d %m}";
          };
          "control-center" = {
            capsule = true;
            capsule_padding = 4.0;
            custom_image = "/home/rdatar/Pictures/NixOS.png";
          };
          media = {
            hide_when_no_media = true;
            max_length = 145;
            title_scroll = "on_hover";
          };
          network.show_label = false;
          notifications.hide_when_no_unread = false;
          volume = {
            scroll_step = 5;
            show_label = false;
          };
          workspaces = {
            display = "id";
            hide_when_empty = true;
            max_label_chars = 2;
          };
        };
      };
    };
  };
}
