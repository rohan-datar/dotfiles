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
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
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
          format-ethernet = "<span size='13000' foreground='#f5e0dc'>󰤭  </span> Disconnected";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "<span size='13000' foreground='#f5e0dc'>  </span>Disconnected";
          tooltip-format-wifi = "Signal Strength: {signalStrength}%";
          on-click = "nm-applet";
        };

        "pulseaudio" = {
          format = "{icon}  {volume}%";
          format-muted = "";
          format-icons = {
            default = ["" "" " "];
          };
          on-click = "pavucontrol";
        };

        "custom/power" = {
          format = "<span foreground='#f5e0dc' ⏻ </span>";
          tooltip = false;
          menu = "on-click";
          menu-file = "$HOME/.config/waybar/power_menu.xml"; # Menu file in resources folder
          menu-actions = {
            shutdown = "shutdown";
            reboot = "reboot";
            suspend = "systemctl suspend";
            hibernate = "systemctl hibernate";
          };
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
      };
    };

    style = ''
      * {
          font-family: "MesloLGS Nerd Font Mono Bold";
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
          margin: 8px;
          padding-left: 8;
          padding-right: 8;
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
      #battery,
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
          color: @blue;
          border-bottom: 2px solid @blue;
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

      #battery {
          color: @green;
          border-bottom: 2px solid @green;
      }

      /* If workspaces is the leftmost module, omit left margin */
            .modules-left>widget:first-child>#workspaces {
          margin-left: 0;
      }

      /* If workspaces is the rightmost module, omit right margin */
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
  };

  home.file = {
    ".config/waybar/power_menu.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <interface>
        <object class="GtkMenu" id="menu">
          <child>
              <object class="GtkMenuItem" id="suspend">
                  <property name="label">Suspend</property>
              </object>
          </child>
          <child>
              <object class="GtkMenuItem" id="hibernate">
                  <property name="label">Hibernate</property>
              </object>
          </child>
          <child>
              <object class="GtkMenuItem" id="shutdown">
                  <property name="label">Shutdown</property>
              </object>
          </child>
          <child>
            <object class="GtkSeparatorMenuItem" id="delimiter1"/>
          </child>
          <child>
              <object class="GtkMenuItem" id="reboot">
                  <property name="label">Reboot</property>
              </object>
          </child>
        </object>
      </interface>
    '';
  };
}
