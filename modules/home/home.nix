{
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  home.stateVersion = "24.05"; # TODO: look into tying this to the os state version

  # reload system units when changing configs
  systemd.user.startServices = mkDefault "sd-switch"; # or "legacy" if "sd-switch" breaks again

  # let HM manage itself when in standalone mode
  programs.home-manager.enable = true;
}
