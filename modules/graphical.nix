let
  graphicalPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
          # firefox
          fastfetch
          obsidian
          discord
          aoc-cli
          direnv
          pandoc
          wireguard-ui
          ;
      };
    };
in
{
  flake.modules.nixos.graphical-packages = graphicalPackages;
  flake.modules.darwin.graphical-packages = graphicalPackages;
}
