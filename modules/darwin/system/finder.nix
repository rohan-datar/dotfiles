{
  system.defaults = {
    # Show hidden files by default
    NSGlobalDomain.AppleShowAllFiles = true;
    NSGlobalDomain.AppleShowAllExtensions = true;

    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
    finder.FXPreferredViewStyle = "Nlsv";

    # Finder: show path bar
    finder.ShowPathBar = true;

    # Keep folders on top when sorting by name
    finder._FXSortFoldersFirst = true;

    # When performing a search, search the current folder by default
    finder.FXDefaultSearchScope = "SCcf";

    # Disable the warning when changing a file extension
    finder.FXEnableExtensionChangeWarning = false;
  };
}
