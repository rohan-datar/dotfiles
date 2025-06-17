{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.hyprpanel.homeManagerModules.hyprpanel];

  programs.hyprpanel = {
    # Enable the module.
    # Default: false
    enable = true;

    # Add '/nix/store/.../hyprpanel' to your
    # Hyprland config 'exec-once'.
    # Default: false
    hyprland.enable = true;

    # Fix the overwrite issue with HyprPanel.
    # See below for more information.
    # Default: false
    overwrite.enable = true;

    settings = {
      layout = {
        "bar.layouts" = {
          "0" = {
            left = ["dashboard" "workspaces" "windowtitle"];
            middle = ["media"];
            right = [
              "volume"
              "network"
              "bluetooth"
              "clock"
              "notifications"
              "power"
            ];
          };
        };
      };
      bar = {
        autoHide = "never";
        bluetooth = {
          label = true;
          middleClick = "";
          rightClick = "";
          scrollDown = "";
          scrollUp = "";
        };
        clock = {
          format = "%a %b %d  %I:%M:%S %p";
          icon = "󰸗";
          middleClick = "";
          rightClick = "";
          scrollDown = "";
          scrollUp = "";
          showIcon = true;
          showTime = true;
        };
        customModules = {
          cpu = {
            icon = "";
            label = true;
            leftClick = "";
            middleClick = "";
            pollingInterval = 2000;
            rightClick = "";
            round = true;
            scrollDown = "";
            scrollUp = "";
          };
          cpuTemp = {
            icon = "";
            label = true;
            leftClick = "";
            middleClick = "";
            pollingInterval = 2000;
            rightClick = "";
            round = true;
            scrollDown = "";
            scrollUp = "";
            sensor = "";
            showUnit = true;
            unit = "metric";
          };
          hypridle = {
            label = true;
            middleClick = "";
            offIcon = "";
            offLabel = "Off";
            onIcon = "";
            onLabel = "On";
            pollingInterval = 2000;
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
          };
          hyprsunset = {
            label = true;
            middleClick = "";
            offIcon = "󰛨";
            offLabel = "Off";
            onIcon = "󱩌";
            onLabel = "On";
            pollingInterval = 2000;
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            temperature = "6000k";
          };
          kbLayout = {
            icon = "󰌌";
            label = true;
            labelType = "code";
            leftClick = "";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
          };
          microphone = {
            label = true;
            leftClick = "menu:audio";
            middleClick = "";
            mutedIcon = "󰍭";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            unmutedIcon = "󰍬";
          };
          netstat = {
            dynamicIcon = false;
            icon = "󰖟";
            label = true;
            labelType = "full";
            leftClick = "";
            middleClick = "";
            networkInLabel = "↓";
            networkInterface = "";
            networkOutLabel = "↑";
            pollingInterval = 2000;
            rateUnit = "auto";
            rightClick = "";
            round = true;
          };
          ram = {
            icon = "";
            label = true;
            labelType = "percentage";
            leftClick = "";
            middleClick = "";
            pollingInterval = 2000;
            rightClick = "";
            round = true;
          };
          scrollSpeed = 5;
          storage = {
            icon = "󰋊";
            label = true;
            labelType = "percentage";
            leftClick = "";
            middleClick = "";
            pollingInterval = 2000;
            rightClick = "";
            round = false;
          };
          submap = {
            disabledIcon = "󰌌";
            disabledText = "Submap off";
            enabledIcon = "󰌐";
            enabledText = "Submap On";
            label = true;
            leftClick = "";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            showSubmapName = true;
          };
          updates = {
            autoHide = false;
            icon = {
              pending = "󰏗";
              updated = "󰏖";
            };
            label = true;
            leftClick = "";
            middleClick = "";
            padZero = true;
            pollingInterval = 1440000;
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            updateCommand = "";
          };
          weather = {
            label = true;
            leftClick = "";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            unit = "imperial";
          };
          worldclock = {
            divider = "  ";
            format = "%I:%M:%S %p %Z";
            formatDiffDate = "%a %b %d  %I:%M:%S %p %Z";
            icon = "󱉊";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            showIcon = true;
            showTime = true;
            tz = [
              "America/New_York"
              "Europe/Paris"
              "Asia/Tokyo"
            ];
          };
        };
        launcher = {
          autoDetectIcon = true;
          middleClick = "";
          rightClick = "";
          scrollDown = "";
          scrollUp = "";
        };
        media = {
          format = "{artist: - }{title}";
          middleClick = "";
          rightClick = "";
          scrollDown = "";
          scrollUp = "";
          show_active_only = false;
          show_label = true;
          truncation = true;
          truncation_size = 30;
        };
        network = {
          label = true;
          showWifiInfo = true;
          truncation = true;
          truncation_size = 7;
        };
        notifications = {
          hideCountWhenZero = false;
          middleClick = "";
          rightClick = "";
          scrollDown = "";
          scrollUp = "";
          show_total = false;
        };
        scrollSpeed = 5;
        volume = {
          label = true;
          middleClick = "";
          rightClick = "";
          scrollDown = "${pkgs.hyprpanel}/bin/hyprpanel 'vol -5'";
          scrollUp = "${pkgs.hyprpanel}/bin/hyprpanel 'vol +5'";
        };
        windowtitle = {
          class_name = true;
          custom_title = true;
          icon = true;
          label = true;
          truncation = true;
          truncation_size = 50;
        };
        workspaces = {
          applicationIconEmptyWorkspace = "";
          applicationIconFallback = "󰣆";
          applicationIconOncePerWorkspace = true;
          icons = {
            active = "";
            available = "";
            occupied = "";
          };
          ignored = "";
          monitorSpecific = true;
          numbered_active_indicator = "underline";
          reverse_scroll = false;
          scroll_speed = 5;
          showAllActive = true;
          showApplicationIcons = false;
          showWsIcons = false;
          show_icons = false;
          show_numbered = true;
          spacing = 1.0;
          workspaceIconMap = {
          };
          workspaceMask = false;
          workspaces = 5;
        };
      };
      dummy = true;
      hyprpanel = {
        restartAgs = true;
        restartCommand = "${pkgs.hyprpanel}/bin/hyprpanel q; ${pkgs.hyprpanel}/bin/hyprpanel";
      };
      menus = {
        clock = {
          time = {
            hideSeconds = false;
            military = false;
          };
        };
        dashboard = {
          controls = {
            enabled = true;
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
                command = "bash -c \"xdg-open $HOME/Projects/\"";
                label = "󰚝 Projects";
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
              image = "$HOME/.face.icon";
              name = "system";
            };
            confirmation = true;
            logout = "hyprctl dispatch exit";
            reboot = "systemctl reboot";
            shutdown = "systemctl poweroff";
            sleep = "systemctl suspend";
          };
          recording = {
            path = "$HOME/Videos/Screencasts";
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
                command = "wofi -show drun";
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
          stats = {
            enable_gpu = true;
            enabled = true;
            interval = 2000;
          };
        };
        media = {
          displayTime = false;
          displayTimeTooltip = false;
          hideAlbum = false;
          hideAuthor = false;
          noMediaText = "No Media Currently Playing";
        };
        transition = "crossfade";
        transitionTime = 200;
        volume = {
          raiseMaximumVolume = false;
        };
      };
      notifications = {
        active_monitor = true;
        cache_actions = true;
        clearDelay = 100;
        displayedTotal = 10;
        ignore = [
        ];
        monitor = 0;
        position = "top right";
        showActionsOnHover = false;
        timeout = 7000;
      };
      scalingPriority = "hyprland";
      tear = false;
      terminal = "ghostty";
      theme = {
        bar = {
          border = {
            location = "none";
            width = "0.15em";
          };
          border_radius = "0.4em";
          buttons = {
            background_hover_opacity = 100;
            background_opacity = 100;
            bluetooth = {
              enableBorder = false;
              spacing = "0.5em";
            };
            borderSize = "0.1em";
            clock = {
              enableBorder = false;
              spacing = "0.5em";
            };
            dashboard = {
              enableBorder = false;
              spacing = "0.5em";
            };
            enableBorders = false;
            innerRadiusMultiplier = "0.4";
            media = {
              enableBorder = false;
              spacing = "0.5em";
            };
            modules = {
              cpu = {
                enableBorder = false;
                spacing = "0.5em";
              };
              cpuTemp = {
                enableBorder = false;
                spacing = "0.5em";
              };
              hypridle = {
                enableBorder = false;
                spacing = "0.45em";
              };
              hyprsunset = {
                enableBorder = false;
                spacing = "0.45em";
              };
              kbLayout = {
                enableBorder = false;
                spacing = "0.45em";
              };
              microphone = {
                enableBorder = false;
                spacing = "0.45em";
              };
              netstat = {
                enableBorder = false;
                spacing = "0.45em";
              };
              power = {
                enableBorder = false;
                spacing = "0.45em";
              };
              ram = {
                enableBorder = false;
                spacing = "0.45em";
              };
              storage = {
                enableBorder = false;
                spacing = "0.45em";
              };
              submap = {
                enableBorder = false;
                spacing = "0.45em";
              };
              updates = {
                enableBorder = false;
                spacing = "0.45em";
              };
              weather = {
                enableBorder = false;
                spacing = "0.45em";
              };
              worldclock = {
                enableBorder = false;
                spacing = "0.45em";
              };
            };
            monochrome = false;
            network = {
              enableBorder = false;
              spacing = "0.5em";
            };
            notifications = {
              enableBorder = false;
              spacing = "0.5em";
            };
            opacity = 100;
            padding_x = "0.7rem";
            padding_y = "0.2rem";
            radius = "0.3em";
            spacing = "0.25em";
            style = "default";
            systray = {
              enableBorder = false;
              spacing = "0.5em";
            };
            volume = {
              enableBorder = false;
              spacing = "0.5em";
            };
            windowtitle = {
              enableBorder = false;
              spacing = "0.5em";
            };
            workspaces = {
              enableBorder = false;
              fontSize = "1.2em";
              numbered_active_highlight_border = "0.2em";
              numbered_active_highlight_padding = "0.2em";
              numbered_inactive_padding = "0.2em";
              pill = {
                active_width = "12em";
                height = "4em";
                radius = "1.9rem * 0.6";
                width = "4em";
              };
              smartHighlight = true;
              spacing = "0.5em";
            };
            y_margins = "0.4em";
          };
          dropdownGap = "2.9em";
          enableShadow = false;
          floating = false;
          label_spacing = "0.5em";
          layer = "top";
          location = "top";
          margin_bottom = "0em";
          margin_sides = "0.5em";
          margin_top = "0.5em";
          menus = {
            border = {
              radius = "0.7em";
              size = "0.13em";
            };
            buttons = {
              radius = "0.4em";
            };
            card_radius = "0.4em";
            enableShadow = false;
            menu = {
              bluetooth = {
                scaling = 100;
              };
              clock = {
                scaling = 100;
              };
              dashboard = {
                confirmation_scaling = 100;
                profile = {
                  radius = "0.4em";
                  size = "8.5em";
                };
                scaling = 100;
              };
              media = {
                card = {
                  tint = 85;
                };
                scaling = 100;
              };
              network = {
                scaling = 100;
              };
              notifications = {
                height = "58em";
                pager = {
                  show = true;
                };
                scaling = 100;
                scrollbar = {
                  radius = "0.2em";
                  width = "0.35em";
                };
              };
              power = {
                radius = "0.4em";
                scaling = 90;
              };
              volume = {
                scaling = 100;
              };
            };
            monochrome = false;
            opacity = 100;
            popover = {
              radius = "0.4em";
              scaling = 100;
            };
            progressbar = {
              radius = "0.3rem";
            };
            scroller = {
              radius = "0.7em";
              width = "0.25em";
            };
            shadow = "0px 0px 3px 1px #16161e";
            shadowMargins = "5px 5px";
            slider = {
              progress_radius = "0.3rem";
              slider_radius = "0.3rem";
            };
            switch = {
              radius = "0.2em";
              slider_radius = "0.2em";
            };
            tooltip = {
              radius = "0.3em";
            };
          };
          opacity = 100;
          outer_spacing = "1.6em";
          scaling = 100;
          shadow = "0px 1px 2px 1px #16161e";
          shadowMargins = "0px 0px 4px 0px";
          transparent = true;
        };
        font = {
          name = "SFProDisplay Nerd Font";
          size = "1.2rem";
          weight = 600;
        };
        name = "catppuccin_mocha_split";
        notification = {
          border_radius = "0.6em";
          enableShadow = false;
          opacity = 100;
          scaling = 100;
          shadow = "0px 1px 2px 1px #16161e";
          shadowMargins = "4px 4px";
        };
        osd = {
          active_monitor = true;
          border = {
            size = "0em";
          };
          duration = 2500;
          enable = true;
          enableShadow = false;
          location = "right";
          margins = "0px 5px 0px 0px";
          monitor = 0;
          muted_zero = false;
          opacity = 100;
          orientation = "vertical";
          radius = "0.4em";
          scaling = 100;
          shadow = "0px 0px 3px 2px #16161e";
        };
        tooltip = {
          scaling = 100;
        };
      };
    };
  };
}
