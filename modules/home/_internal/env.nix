{ config, ... }:
let
  inherit (config.flake.meta) defaults;
in
{
  flake.modules.homeManager.env =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (pkgs.stdenv) isLinux;

      flakePath = "${config.home.homeDirectory}/nix";

      # Map browser names to their .desktop file names
      browserDesktopFile =
        {
          firefox = "firefox.desktop";
          chromium = "chromium-browser.desktop";
          floorp = "floorp.desktop";
          zen = "zen-beta.desktop";
        }
        .${defaults.browser} or "${defaults.browser}.desktop";

      browser = [
        "text/html"
        "application/pdf"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/ftp"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ];

      code = [
        "application/json"
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];

      associations =
        (lib.genAttrs code (_: [ "nvim.desktop" ]))
        // (lib.genAttrs browser (_: [ browserDesktopFile ]))
        // {
          "x-scheme-handler/discord" = [ "Discord.desktop" ];
          "inode/directory" = [
            "${defaults.fileManager}.desktop"
          ];
        };
    in
    {
      home.sessionVariables = {
        EDITOR = defaults.editor;
        GIT_EDITOR = defaults.editor;
        VISUAL = defaults.editor;
        TERMINAL = defaults.terminal;
        SYSTEMD_PAGERSECURE = "true";
        PAGER = defaults.pager;
        MANPAGER = defaults.manpager;
        FLAKE = flakePath;
        NH_FLAKE = flakePath;
        DO_NOT_TRACK = 1;
      };

      home.shell = {
        enableShellIntegration = false;
        enableBashIntegration = config.programs.bash.enable;
        enableIonIntegration = config.programs.ion.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;
        enableFishIntegration = config.programs.fish.enable;
      };

      xdg = {
        enable = true;

        cacheHome = "${config.home.homeDirectory}/.cache";
        configHome = "${config.home.homeDirectory}/.config";
        dataHome = "${config.home.homeDirectory}/.local/share";
        stateHome = "${config.home.homeDirectory}/.local/state";

        userDirs = mkIf isLinux {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;

          documents = "${config.home.homeDirectory}/Documents";
          download = "${config.home.homeDirectory}/Downloads";
          desktop = "${config.home.homeDirectory}/Desktop";
          videos = "${config.home.homeDirectory}/Media/Videos";
          music = "${config.home.homeDirectory}/Media/Music";
          pictures = "${config.home.homeDirectory}/Media/Pictures";
          publicShare = "${config.home.homeDirectory}/Public/share";

          extraConfig = {
            SCREENSHOTS = "${config.xdg.userDirs.pictures}/screenshots";
            DEV = "${config.home.homeDirectory}/Documents/dev";
          };
        };

        mimeApps = {
          enable = isLinux;
          associations.added = associations;
          defaultApplications = associations;
        };
      };
    };
}
