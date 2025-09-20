{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  documentation = {
    enable = mkForce false;
    dev.enable = mkForce true;
    doc.enable = mkForce false;
    info.enable = mkForce false;
    nixos.enable = mkForce false;

    man = {
      enable = mkForce true;
      generateCaches = mkForce false;
      man-db.enable = mkForce false;
      mandoc.enable = mkForce false;
    };
  };
}
