{
  flake.modules.nixos.xserver =
    { pkgs, ... }:
    {
      services.xserver = {
        enable = false;
        desktopManager.xterm.enable = false;

        excludePackages = [ pkgs.xterm ];
      };
    };
}
