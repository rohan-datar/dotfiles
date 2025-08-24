{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  cfg = config.olympus.aspects;
  inherit (lib) mkEnableOption mkOption types;
in
{

  config = lib.mkIf cfg.graphical.enable {
    # shared with all systems
    olympus.packages = {
      inherit (pkgs)
        firefox
        # ghostty # currently marked as broken on darwin
        neofetch
        lazygit
        obsidian
        discord
        aoc-cli
        direnv
        pandoc
        wireshark
        floorp
        vscode
        wiregurard-ui
        bitwarden-desktop
        ;
    };
  };
}
