{
  lib,
  pkgs,
  self,
  config,
  ...
}:
let
  inherit (lib.modules) mkForce;
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv) isLinux;

  inherit (config.olympus.programs) defaults;

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

  media = [
    "video/*"
    "audio/*"
  ];

  images = [ "image/*" ];

  associations =
    (lib.genAttrs code (_: [ "nvim.desktop" ]))
    // (lib.genAttrs browser (_: [
      "${defaults.browser}.desktop"
    ]))
    // {
      "x-scheme-handler/discord" = [ "Discord.desktop" ];
      "inode/directory" = [
        "${defaults.fileManager}.desktop"
      ];
    };
in
{
  xdg = {
    enable = true;

    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";

    userDirs = mkIf isLinux {
      enable = true;
      createDirectories = true;

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
}
