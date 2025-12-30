{
  inputs,
  pkgs,
  lib,
  osConfig ? null,
  enableRdmacs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # Check if NixOS services.emacs is enabled (provides the package)
  nixosEmacsEnabled = osConfig != null && osConfig.services.emacs.enable or false;
in
{
  imports = lib.optionals enableRdmacs [
    inputs.editorconfig.homeModules.rdmacs
  ];

  config = lib.mkIf enableRdmacs {
    programs.rdmacs = {
      enable = true;
      package = inputs.editorconfig.packages.${system}.rdmacs;
      initFile = inputs.editorconfig.packages.${system}.rdmacs-init;
      # Don't install package if NixOS services.emacs is providing it
      installPackage = !nixosEmacsEnabled;
    };
  };
}
