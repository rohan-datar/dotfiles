{
  flake.modules.nixos.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.man-pages
        pkgs.man-pages-posix
        pkgs.ghostty.terminfo
      ];
    };
}
