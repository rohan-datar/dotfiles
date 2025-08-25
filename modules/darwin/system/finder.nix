{
  system.defaults = {
    # Show hidden files by default
    NSGlobalDomain.AppleShowAllFiles = true;
    NSGlobalDomain.AppleShowAllExtensions = true;

    finder = {
      # show all file extensions
      AppleShowAllExtensions = true;

      # Use list view in all Finder windows by default
      # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
      FXPreferredViewStyle = "Nlsv";

      # Keep folders on top when sorting by name
      _FXSortFoldersFirst = true;

      # When performing a search, search the current folder by default
      FXDefaultSearchScope = "SCcf";

      # Disable the warning when changing a file extension
      FXEnableExtensionChangeWarning = false;
    };
  };
}
