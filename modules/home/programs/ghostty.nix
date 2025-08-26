{
  pkgs,
  config,
  ...
}:
{
  programs.ghostty = {
    inherit (config.olympus.aspects.graphical) enable;
    package = if pkgs.stdenv.hostPlatform.isLinux then pkgs.ghostty else null;

    settings = {
      theme = "catppuccin-mocha";
      background-opacity = 0.85;

      background-blur-radius = 16;
      window-decoration = false;

      # font
      font-family = pkgs.lib.mkForce "Maple Mono NF";
      font-size = pkgs.lib.mkForce 16;

      # shell stuff
      shell-integration = "detect";
      cursor-style = "block";
    };
  };
}
