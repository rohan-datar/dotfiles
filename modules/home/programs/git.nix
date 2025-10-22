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

    attributes = [
      "* text=auto"
    ];

    settings = mkMerge [
      {
        user = {
          email = "me@rohandatar.com";
          name = "Rohan Datar";
        };
        aliases = {
          diff = "diff --word-diff";
          blame = "blame -C -C -C";
        };
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
