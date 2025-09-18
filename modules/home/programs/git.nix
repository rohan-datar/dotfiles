{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
in
{
  programs.git = {
    enable = true;
    userEmail = "me@rohandatar.com";
    userName = "Rohan Datar";

    attributes = [
      "* text=auto"
    ];

    aliases = {
      diff = "diff --word-diff";
      blame = "blame -C -C -C";
    };

    extraConfig = mkMerge [
      {
        merge.conflictstyle = "diff3";
        rerere.enabled = "true";
      }

      (mkIf pkgs.stdenv.hostPlatform.isLinux {
        credential.helper = "store";
      })

      (mkIf pkgs.stdenv.hostPlatform.isDarwin {
        credential.helper = [
          ""
          "osxkeychain"
        ];
      })
    ];
  };
}
