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
  };
}
