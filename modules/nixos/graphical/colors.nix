{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.olympus.aspects;
in
{
  config = lib.mkIf cfg.graphical.enable {
    stylix = {
      enable = true;
      base16Scheme = "${inputs.tinted-schemes}/base24/catppuccin-mocha.yaml";

      opacity =
        let
          default_opacity = 0.85;
        in
        {
          desktop = default_opacity;
          terminal = default_opacity;
        };
    };
  };
}
