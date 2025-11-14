{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];
  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
    settings = {
      appLauncher = {
        terminalCommand = "ghostty -e";
      };
      audio = {
        preferredPlayer = "Apple Music";
        visualizerQuality = "low";
      };
      bar = {
        backgroundOpacity = 0;
        density = "comfortable";
        widgets = {
          center = [
            {
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              useCustomFont = false;
              usePrimaryColor = true;
            }
          ];
          left = [
            {
              colorizeDistroLogo = true;
              customIconPath = "";
              icon = "";
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              colorizeIcons = false;
              hideMode = "hidden";
              id = "ActiveWindow";
              maxWidth = 145;
              scrollingMode = "hover";
              showIcon = true;
              useFixedWidth = false;
            }
            {
              hideMode = "hidden";
              hideWhenIdle = false;
              id = "MediaMini";
              maxWidth = 145;
              scrollingMode = "hover";
              showAlbumArt = true;
              showVisualizer = true;
              useFixedWidth = false;
              visualizerType = "linear";
            }
            {
              characterCount = 2;
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "index";
            }
          ];
          right = [
            {
              id = "SystemMonitor";
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskUsage = false;
              showMemoryAsPercent = false;
              showMemoryUsage = true;
              showNetworkStats = false;
              usePrimaryColor = true;
            }
            {
              id = "ScreenRecorder";
            }
            {
              displayMode = "onhover";
              id = "WiFi";
            }
            {
              displayMode = "onhover";
              id = "Bluetooth";
            }
            {
              displayMode = "onhover";
              id = "Volume";
            }
            {
              hideWhenZero = true;
              id = "NotificationHistory";
              showUnreadBadge = true;
            }
            {
              id = "SessionMenu";
            }
          ];
        };
      };
      colorSchemes = {
        darkMode = true;
        generateTemplatesForPredefined = true;
        manualSunrise = "06:30";
        manualSunset = "18:30";
        matugenSchemeType = "scheme-fruit-salad";
        predefinedScheme = "Catppuccin";
        schedulingMode = "off";
        useWallpaperColors = false;
      };
      controlCenter = {
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
        position = "close_to_bar_button";
        shortcuts = {
          left = [
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
            {
              id = "ScreenRecorder";
            }
            {
              id = "WallpaperSelector";
            }
          ];
          right = [
            {
              id = "Notifications";
            }
            {
              id = "KeepAwake";
            }
            {
              id = "NightLight";
            }
          ];
        };
      };
      dock = {
        enabled = false;
      };
      general = {
        avatarImage = ../assets/HAL-9000-icon.png;
        radiusRatio = 1;
        scaleRatio = 1.1;
      };
      hooks = {
        darkModeChange = "";
        enabled = false;
        wallpaperChange = "";
      };
      location = {
        analogClockInCalendar = false;
        firstDayOfWeek = -1;
        name = "Madison, WI";
        showCalendarEvents = true;
        showCalendarWeather = true;
        showWeekNumberInCalendar = false;
        use12hourFormat = true;
        useFahrenheit = false;
        weatherEnabled = true;
      };
      network = {
        wifiEnabled = false;
      };
      nightLight = {
        autoSchedule = true;
        dayTemp = "6500";
        enabled = true;
        forced = false;
        manualSunrise = "06:30";
        manualSunset = "18:30";
        nightTemp = "4000";
      };
      osd = {
        enabled = true;
        backgroundOpacity = 0;
        location = "right";
      };
      screenRecorder = {
        audioCodec = "opus";
        audioSource = "default_output";
        colorRange = "limited";
        directory = "/home/rdatar/Videos";
        frameRate = 60;
        quality = "very_high";
        showCursor = true;
        videoCodec = "h264";
        videoSource = "portal";
      };
      sessionMenu = {
        countdownDuration = 5000;
        enableCountdown = false;
        position = "top_right";
        powerOptions = [
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
        showHeader = true;
      };
      settingsVersion = 22;
      setupCompleted = true;
      ui = {
        fontDefault = "SFProDisplay Nerd Font";
        fontDefaultScale = 1.11;
        fontFixed = "MesloLGS Nerd Font";
        fontFixedScale = 1.11;
        panelBackgroundOpacity = 1;
        panelsAttachedToBar = true;
        settingsPanelAttachToBar = false;
        tooltipsEnabled = true;
      };
      wallpaper = {
        directory = "~/.local/share/backgrounds/";
        enableMultiMonitorDirectories = false;
        enabled = true;
        fillColor = "#000000";
        fillMode = "crop";
        hideWallpaperFilenames = false;
        overviewEnabled = false;
        panelPosition = "follow_bar";
        randomEnabled = true;
        randomIntervalSec = 300;
        recursiveSearch = false;
        setWallpaperOnAllMonitors = true;
        transitionDuration = 1500;
        transitionEdgeSmoothness = {
        };
        transitionType = "random";
      };
    };
  };
}
