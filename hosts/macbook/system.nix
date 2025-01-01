{
  config,
  pkgs,
  ...
}: {
  users.users.rohandatar = {
    name = "rohandatar";
    home = "/Users/rohandatar";
  };
  # Import this module in your nix-darin config to have applications copied
  # to /Applications/Nix Apps instead of being symlinked. GUI apps must be
  # added to environment packages, not home-manager for this to work.
  system.activationScripts.postUserActivation.text = ''
    apps_source="${config.system.build.applications}/Applications"
    moniker="Nix Trampolines"
    app_target_base="$HOME/Applications"
    app_target="$app_target_base/$moniker"
    mkdir -p "$app_target"
    ${pkgs.rsync}/bin/rsync --archive --checksum --chmod=-w --copy-unsafe-links --delete "$apps_source/" "$app_target"
  '';

  system.defaults = {
    loginwindow.GuestEnabled = false;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.KeyRepeat = 2;

    # Expand save panel by default
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

    # Expand print panel by default
    NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
    NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;

    # Enable subpixel font rendering on non-Apple LCDs
    # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
    NSGlobalDomain.AppleFontSmoothing = 1;

    # Show hidden files by default
    NSGlobalDomain.AppleShowAllFiles = true;
    NSGlobalDomain.AppleShowAllExtensions = true;

    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
    finder.FXPreferredViewStyle = "Nlsv";

    # Finder: show path bar
    # finder.ShowPathBar = true;

    # Keep folders on top when sorting by name
    finder._FXSortFoldersFirst = true;

    # When performing a search, search the current folder by default
    finder.FXDefaultSearchScope = "SCcf";

    # Disable the warning when changing a file extension
    finder.FXEnableExtensionChangeWarning = false;

    # Disable the “Are you sure you want to open this application?” dialog
    LaunchServices.LSQuarantine = false;

    # Save screenshots to the desktop
    screencapture.location = "~/Desktop/Screenshots";

    NSGlobalDomain._HIHideMenuBar = true;

    dock.autohide = true;
  };
}
