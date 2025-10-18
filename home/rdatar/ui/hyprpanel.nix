{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    programs.hyprpanel = {
      enable = true;

      systemd.enable = true;

      dontAssertNotificationDaemons = true;

      settings = {
        bar = {
          layouts = {
            "*" = {
              left = [
                "dashboard"
                "workspaces"
                "windowtitle"
                "media"
              ];
              middle = [
                "clock"
              ];
              right = [
                "cpu"
                "ram"
                "bluetooth"
                "network"
                "volume"
                "notifications"
                "power"
              ];
            };
          };
          clock.showIcon = false;
          notifications = {
            show_total = true;
          };
          volume = {
            label = true;
            scrollDown = "${pkgs.hyprpanel}/bin/hyprpanel 'vol -5'";
            scrollUp = "${pkgs.hyprpanel}/bin/hyprpanel 'vol +5'";
          };
          workspaces = {
            show_numbered = true;
          };
          launcher.autoDetectIcon = true;
        };
        dummy = true;
        hyprpanel = {
          restartAgs = true;
          restartCommand = "${pkgs.hyprpanel}/bin/hyprpanel q; ${pkgs.hyprpanel}/bin/hyprpanel";
        };
        menus = {
          clock = {
            weather.enabled = false;
          };
          dashboard = {
            controls = {
              enabled = false;
            };
            directories = {
              enabled = true;
              left = {
                directory1 = {
                  command = "bash -c \"xdg-open $HOME/Downloads/\"";
                  label = "󰉍 Downloads";
                };
                directory2 = {
                  command = "bash -c \"xdg-open $HOME/Videos/\"";
                  label = "󰉏 Videos";
                };
                directory3 = {
                  command = "bash -c \"xdg-open $HOME/nix/\"";
                  label = " Nix Config";
                };
              };
              right = {
                directory1 = {
                  command = "bash -c \"xdg-open $HOME/Documents/\"";
                  label = "󱧶 Documents";
                };
                directory2 = {
                  command = "bash -c \"xdg-open $HOME/Pictures/\"";
                  label = "󰉏 Pictures";
                };
                directory3 = {
                  command = "bash -c \"xdg-open $HOME/\"";
                  label = "󱂵 Home";
                };
              };
            };
            powermenu = {
              avatar = {
                image = ../assets/HAL-9000-icon.png;
                name = "system";
              };
            };
            shortcuts = {
              enabled = true;
              left = {
                shortcut1 = {
                  command = "zen";
                  icon = "󰖟";
                  tooltip = "Zen Browser";
                };
                shortcut2 = {
                  command = "ghostty";
                  icon = "󰊠";
                  tooltip = "Ghostty";
                };
                shortcut3 = {
                  command = "discord";
                  icon = "";
                  tooltip = "Discord";
                };
                shortcut4 = {
                  command = "fuzzel";
                  icon = "";
                  tooltip = "Search Apps";
                };
              };
              right = {
                shortcut1 = {
                  command = "sleep 0.5 && hyprpicker -a";
                  icon = "";
                  tooltip = "Color Picker";
                };
                shortcut3 = {
                  command = "bash -c \"/nix/store/l3s52iggy014p38vi1ri5mi4rjb4qggb-snapshot.sh\"";
                  icon = "󰄀";
                  tooltip = "Screenshot";
                };
              };
            };
          };
        };
        scalingPriority = "hyprland";
        terminal = "ghostty";

        theme = {
          "font.name" = "SFProDisplay Nerd Font";
          "bar.transparent" = "true";
        };
      };
    };
  };
}
