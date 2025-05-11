{
  config,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        # // "layer": "top", // Waybar at top layer
        # // "position": "bottom", // Waybar position (top|bottom|left|right)
        spacing = 6; # Gaps between modules (4px)
        # Choose the order of the modules
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [
          "mpris"
        ];
        modules-right = [
          "bluetooth"
          "network"
          "pulseaudio"
          "clock"
          "custom/notification"
          "custom/power"
        ];

        # Modules configuration
        "clock" = {
          format = "<span foreground='#f5c2e7'>   </span>{:%a %d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "network" = {
          format-wifi = "<span size='13000' foreground='#f5e0dc'>  </span>{essid}";
          format-ethernet = "<span size='13000' foreground='#f5e0dc'> 󰈀 </span>";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "<span size='13000' foreground='#f5e0dc'>  </span>Disconnected";
          tooltip-format-wifi = "Signal Strength: {signalStrength}%";
          tooltip-format-ethernet = "{ipaddr}/{cidr} via {gwaddr}";
          on-click = "networkmanager_dmenu";
        };

        "pulseaudio" = {
          format = "{icon}  {volume}%";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-muted = " {format-source}";
          format-icons = {
            headphone = " ";
            hands-free = " ";
            headset = " ";
            phone = " ";
            portable = " ";
            car = " ";
            default = ["" "" " "];
          };
          on-click = "pavucontrol";
        };

        "bluetooth" = {
          format = " {status}";
          # format-disabled= "";
          # format-off= "";
          interval = 30;
          on-click = "blueman-manager";
          # format-no-controller= "";
        };

        "custom/power" = {
          format = "<span foreground='#f5e0dc'> ⏻ </span>";
          on-click = "wlogout";
          tooltip-format = "Power Menu";
        };

        "custom/notification" = {
          tooltip = false;
          format = "<span foreground='#f5c2e7'> {} {icon} </span>";
          "format-icons" = {
            notification = "󱅫";
            none = "";
            "dnd-notification" = " ";
            "dnd-none" = "󰂛";
            "inhibited-notification" = " ";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = " ";
            "dnd-inhibited-none" = " ";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          exec = "swaync-client -swb";
          "on-click" = "sleep 0.1 && swaync-client -t -sw";
          "on-click-right" = "sleep 0.1 && swaync-client -d -sw";
          escape = true;
        };

        "mpris" = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "▶";
            mpv = "🎵";
          };
          status-icons = {
            paused = "⏸";
          };
          # "ignored-players": ["firefox"]
        };
      };
    };

    style = ''
        * {
            font-family: "meslolgs nerd font mono bold";
            font-size: 16px;
            min-height: 0;
            font-weight: bold;
        }

        window#waybar {
            background: transparent;
            background-color: @crust;
            color: @overlay0;
            transition-property: background-color;
            transition-duration: 0.1s;
            border-bottom: 1px solid @overlay1;
        }

        #window {
            color: @flamingo;
            background: @mantle;
            margin: 10px 15px 10px 0px;
            padding: 2px 10px 0px 10px;
            border-radius: 12px;
        }

        #mpris {
            color: @teal;
            background: @mantle;
            margin: 10px 15px 10px 0px;
            padding: 2px 10px 0px 10px;
            border-radius: 12px;
        }

        button {
            box-shadow: inset 0 -3px transparent;
            border: none;
            border-radius: 0;
        }

        button:hover {
            background: inherit;
            color: @mauve;
            border-top: 2px solid @mauve;
        }

        #workspaces button {
            padding: 0 4px;
        }

        #workspaces button.focused {
            background-color: rgba(0, 0, 0, 0.3);
            color: @rosewater;
            border-top: 2px solid @rosewater;
        }

        #workspaces button.active {
            background-color: rgba(0, 0, 0, 0.3);
            color: @mauve;
            border-top: 2px solid @mauve;
        }

        #workspaces button.urgent {
                  background-color: #eb4d4b;
        }

        #pulseaudio,
        #clock,
        #bluetooth,
        #cpu,
        #memory,
        #disk,
        #temperature,
        #backlight,
        #wireplumber,
        #tray,
        #network,
        #mode,
        #scratchpad {
          margin-top: 2px;
          margin-bottom: 2px;
          margin-left: 4px;
          margin-right: 4px;
          padding-left: 4px;
          padding-right: 4px;
        }

        #clock {
            color: @maroon;
            border-bottom: 2px solid @maroon;
        }

        #clock.date {
            color: @mauve;
            border-bottom: 2px solid @mauve;
        }

        #pulseaudio {
            color: @green;
            border-bottom: 2px solid @green;
        }

      #network {
          color: @yellow;
          border-bottom: 2px solid @yellow;
      }

        #idle_inhibitor {
            margin-right: 12px;
                  color: #7cb342;
        }

        #idle_inhibitor.activated {
            color: @red;
        }

        #bluetooth {
            color: @blue;
            border-bottom: 2px solid @blue;
        }

        /* if workspaces is the leftmost module, omit left margin */
              .modules-left>widget:first-child>#workspaces {
            margin-left: 0;
        }

        /* if workspaces is the rightmost module, omit right margin */
              .modules-right>widget:last-child>#workspaces {
            margin-right: 0;
        }

        #custom-vpn {
            color: @lavender;
            border-radius: 15px;
            padding-left: 6px;
            padding-right: 6px;
        }
    '';

    # style = ''

    #   * {
    #       font-family: "meslolgs nerd font mono bold";
    #       font-size: 16px;
    #       min-height: 0;
    #       font-weight: bold;
    #   }

    #   #waybar {
    #     background: transparent;
    #     color: @text;
    #     margin: 5px 5px;
    #   }

    #   #workspaces {
    #     border-radius: 1rem;
    #     margin: 5px;
    #     background-color: @surface0;
    #     margin-left: 1rem;
    #   }

    #   #workspaces button {
    #     color: @lavender;
    #     border-radius: 1rem;
    #     padding: 0.4rem;
    #   }

    #   #workspaces button.active {
    #     color: @sky;
    #     border-radius: 1rem;
    #   }

    #   #workspaces button:hover {
    #     color: @sapphire;
    #     border-radius: 1rem;
    #   }

    #   #pulseaudio,
    #   #clock,
    #   #bluetooth,
    #   #cpu,
    #   #memory,
    #   #disk,
    #   #temperature,
    #   #backlight,
    #   #wireplumber,
    #   #tray,
    #   #network,
    #   #mode,
    #   #custom-power {
    #     background-color: @surface0;
    #     padding: 0.5rem 1rem;
    #     margin: 5px 0;
    #   }

    #   #clock {
    #     color: @blue;
    #     border-radius: 0px 1rem 1rem 0px;
    #     margin-right: 1rem;
    #   }

    #   #network {
    #       color: @yellow;
    #       border-bottom: 2px solid @yellow;
    #   }

    #   #pulseaudio {
    #     color: @maroon;
    #     border-radius: 1rem 0px 0px 1rem;
    #     margin-left: 1rem;
    #   }

    #   #custom-music {
    #     color: @mauve;
    #     border-radius: 1rem;
    #   }

    #   #custom-lock {
    #       border-radius: 1rem 0px 0px 1rem;
    #       color: @lavender;
    #   }

    #   #custom-power {
    #       margin-right: 1rem;
    #       border-radius: 0px 1rem 1rem 0px;
    #       color: @red;
    #   }

    #   #tray {
    #     margin-right: 1rem;
    #     border-radius: 1rem;
    #   }
    # '';
  };
}
