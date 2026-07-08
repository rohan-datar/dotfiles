_: {
  flake.modules.darwin.system = {
    system = {
      primaryUser = "rohandatar";

      defaults = {
        NSGlobalDomain = {
          AppleICUForce24HourTime = false;
          AppleShowAllFiles = true;
          AppleShowAllExtensions = true;

          NSNavPanelExpandedStateForSaveMode = true;
          NSNavPanelExpandedStateForSaveMode2 = true;
          PMPrintingExpandedStateForPrint = true;
          PMPrintingExpandedStateForPrint2 = true;
          AppleFontSmoothing = 1;

          # disable auto substitutions
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
        };

        menuExtraClock = {
          Show24Hour = true;
          IsAnalog = false;
          ShowAMPM = true;
          ShowDayOfMonth = true;
          ShowDayOfWeek = true;
          ShowSeconds = false;
        };

        dock.autohide = true;

        finder = {
          AppleShowAllExtensions = true;
          FXPreferredViewStyle = "Nlsv";
          _FXSortFoldersFirst = true;
          FXDefaultSearchScope = "SCcf";
          FXEnableExtensionChangeWarning = false;
        };

        LaunchServices.LSQuarantine = false;
        CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising = false;

        CustomUserPreferences = {
          # Add a context menu item for showing the Web Inspector in web views
          NSGlobalDomain.WebKitDeveloperExtras = true;

          "com.apple.desktopservices" = {
            # Avoid creating .DS_Store files on network or USB volumes
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
        };
      };
    };

    # Increase system-wide file descriptor limits for macOS
    launchd.daemons.limit-maxfiles = {
      serviceConfig = {
        Label = "limit.maxfiles";
        ProgramArguments = [
          "launchctl"
          "limit"
          "maxfiles"
          "64000"
          "524288"
        ];
        RunAtLoad = true;
      };
    };

    # allow for using Touch ID for sudo authentication
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}
