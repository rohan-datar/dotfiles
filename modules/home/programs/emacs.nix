{
  inputs,
  pkgs,
  lib,
  config,
  osConfig ? null,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.olympus.aspects.graphical;

  # Check if NixOS services.emacs is enabled (provides the package)
  nixosEmacsEnabled = osConfig != null && osConfig.services.emacs.enable or false;
in
{
  config = lib.mkIf (cfg.enable && !nixosEmacsEnabled) {
    home.packages = [
      inputs.editorconfig.packages.${system}.rdmacs-wrapped
    ];
  };
}
