{lib, ...}: let
  inherit (lib) mkForce;
in {
  programs = {
    info.enable = mkForce false;
    man.enable = mkForce false;
  };
}
