{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf genAttrs;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    olympus.packages = { inherit (pkgs) appimage-run; };

    # run appimages with appimage-run
    boot.binfmt.registrations =
      genAttrs
        [
          "appimage"
          "AppImage"
        ]
        (ext: {
          recognitionType = "extension";
          magicOrExtension = ext;
          interpreter = "/run/current-system/sw/bin/appimage-run";
        });

    # run unpatched linux binaries with nix-ld
    programs.nix-ld = {
      enable = true;
      libraries = builtins.attrValues {
        inherit (pkgs)
          openssl
          curl
          glib
          util-linux
          glibc
          icu
          libunwind
          libuuid
          zlib
          libsecret
          freetype
          libglvnd
          libnotify
          sdl3
          vulkan-loader
          gdk-pixbuf
          libX11
          ;
        inherit (pkgs.stdenv.cc) cc;
      };
    };
  };
}
