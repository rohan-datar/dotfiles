{
  pkgs,
  config,
  ...
}:
{
  programs.kitty = {
    inherit (config.olympus.aspects.graphical) enable;
    font = {
      name = pkgs.lib.mkForce "Maple Mono NF";
      size = pkgs.lib.mkForce 14;
    };
  };
}
