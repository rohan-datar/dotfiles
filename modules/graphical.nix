{ self, ... }:
let
  graphicalPackages =
    {
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages =
        builtins.attrValues {
          inherit (pkgs)
            firefox
            fastfetch
            # obsidian
            discord
            aoc-cli
            direnv
            pandoc
            wireguard-ui
            ;
        }
        ++ [
          (lib.hiPrio self.packages.${pkgs.stdenv.hostPlatform.system}.ghostty)
        ];
    };
in
{
  flake.modules.nixos.graphical-packages = graphicalPackages;
  flake.modules.darwin.graphical-packages = graphicalPackages;
}
