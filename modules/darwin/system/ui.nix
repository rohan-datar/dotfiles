{
  # UI settings
  system.defaults = {
    # Expand save panel by default
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

    # Expand print panel by default
    NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
    NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;

    # Set accent color to blue
    NSGlobalDomain.AppleAccentColor = "1";

    # Show battery percentage in menu bar
    NSGlobalDomain.ShowBatteryPercentage = true;

    # Enable subpixel font rendering on non-Apple LCDs
    # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
    NSGlobalDomain.AppleFontSmoothing = 1;

    # NSGlobalDomain._HIHideMenuBar = true;
    dock.autohide = true;
  };
}
