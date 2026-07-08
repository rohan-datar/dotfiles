{ lib, ... }:
let
  sharedDocumentation = {
    documentation = {
      enable = true;
      man.enable = true;
      info.enable = true;
    };
  };
in
{
  flake.modules.nixos.documentation = {
    imports = [ sharedDocumentation ];
    config = {
      documentation = {
        enable = lib.mkForce true;
        dev.enable = lib.mkForce true;
        doc.enable = lib.mkForce false;
        info.enable = lib.mkForce false;
        nixos.enable = lib.mkForce false;

        man = {
          enable = lib.mkForce true;
          cache.enable = lib.mkForce false;
          man-db.enable = lib.mkForce true;
          mandoc.enable = lib.mkForce false;
        };
      };
    };
  };

  flake.modules.darwin.documentation = {
    imports = [ sharedDocumentation ];
    config = {
      documentation = {
        man.enable = lib.mkForce false;
        doc.enable = lib.mkForce false;
      };

      programs = {
        info.enable = lib.mkForce false;
        man.enable = lib.mkForce false;
      };

      # The darwin-uninstaller package embeds its own internal nix-darwin system
      # (built from nix-darwin's bundled minimal config) which enables
      # documentation by default and pulls in the broken `darwin-manual-html`.
      # Disable it until upstream nix-darwin fixes the nixos-render-docs breakage.
      system.tools.darwin-uninstaller.enable = lib.mkForce false;
    };
  };
}
