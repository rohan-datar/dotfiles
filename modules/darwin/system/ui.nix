{
  # UI settings
  system.defaults = {
    # Expand save panel by default
    NSGlobalDomain = {
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;

      # Expand print panel by default
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;

      # Enable subpixel font rendering on non-Apple LCDs
      # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
      AppleFontSmoothing = 1;
    };

    # NSGlobalDomain._HIHideMenuBar = true;
    dock.autohide = true;
  };
}
