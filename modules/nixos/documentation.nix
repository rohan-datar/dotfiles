{ lib, pkgs, ... }:
let
  inherit (lib) mkForce;
in
{
  documentation = {
    enable = mkForce true;
    dev.enable = mkForce true;
    doc.enable = mkForce false;
    info.enable = mkForce false;
    nixos.enable = mkForce false;

    man = {
      enable = mkForce true;
      cache.enable = mkForce false;
      man-db.enable = mkForce true;
      mandoc.enable = mkForce false;
    };
  };

  olympus.packages = {
    inherit (pkgs)
      man-pages
      man-pages-posix
      ;
  };
}
