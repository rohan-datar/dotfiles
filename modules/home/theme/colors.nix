{ inputs, ... }:
{
  imports = [ inputs.stylix.homeModules.stylix ];

  config = {
    stylix = {
      enable = true;
      base16Scheme = "${inputs.tinted-schemes}/base24/catppuccin-mocha.yaml";
      polarity = "dark";

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
