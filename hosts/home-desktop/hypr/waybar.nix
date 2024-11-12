{ config, pkgs, ... }:
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        # // "layer": "top", // Waybar at top layer
        # // "position": "bottom", // Waybar position (top|bottom|left|right)
        height = 30; # Waybar height (to be removed for auto height)
        spacing = 4; # Gaps between modules (4px)
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
            format = "⏻ ";
            tooltip= false;
            menu= "on-click";
            menu-file= "$HOME/.config/waybar/power_menu.xml"; # Menu file in resources folder
            menu-actions= {
                shutdown= "shutdown";
                reboot= "reboot";
                suspend= "systemctl suspend";
                hibernate= "systemctl hibernate"
            };
        };
    };
    };
  };
}
