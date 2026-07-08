{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  flake.modules.homeManager.base = {
    home.stateVersion = "25.11";

    # reload system units when changing configs
    systemd.user.startServices = mkDefault "sd-switch";

    # let HM manage itself when in standalone mode
    programs.home-manager.enable = true;
  };
}
