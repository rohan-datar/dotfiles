{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  documentation = {
    man.enable = mkForce false;
    doc.enable = mkForce false;
  };

  programs = {
    info.enable = mkForce false;
    man.enable = mkForce false;
  };

  # The darwin-uninstaller package embeds its own internal nix-darwin system
  # (built from nix-darwin's bundled minimal config) which enables
  # documentation by default and pulls in the broken `darwin-manual-html`.
  # Disable it until upstream nix-darwin fixes the nixos-render-docs breakage.
  system.tools.darwin-uninstaller.enable = mkForce false;
}
