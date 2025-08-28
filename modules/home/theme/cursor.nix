{ pkgs, ... }:
{
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.mochaBlue;
    name = "Catppuccin Mocha Blue";
    size = 45;
  };
}
