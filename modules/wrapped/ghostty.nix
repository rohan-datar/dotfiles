_: {
  flake.wrappers.ghostty =
    {
      wlib,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.ghostty ];

      settings = {
        theme = "Catppuccin Mocha";
        background-opacity = 0.85;
        background-blur-radius = 16;
        window-decoration = false;

        # font
        font-family = "Maple Mono NF";
        font-size = 16;

        # shell stuff
        shell-integration = "detect";
        cursor-style = "block";
        keybind = [
          "ctrl+left_bracket=text:\x1b"
        ];
      };

      # GUI launches on macOS (Dock/Spotlight) execute the binary inside
      # Ghostty.app, not bin/ghostty, so wrap that path too. LaunchServices
      # requires the app bundle executable to be a real binary rather than a
      # shell script, hence the binary wrapper implementation for the variant.
      # The top-level bin/ghostty keeps the default implementation, which
      # retains the argv0type handling for ghostty's +actions/--help (their
      # parsers reject --config-file and would silently exit).
      wrapperVariants.macAppBundle = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        exePath = "Applications/Ghostty.app/Contents/MacOS/ghostty";
        binDir = "Applications/Ghostty.app/Contents/MacOS";
        binName = "ghostty";
        wrapperImplementation = "binary";
      };
    };
}
