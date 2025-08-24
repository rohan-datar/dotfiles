{lib, ...}: {
  imports = [
    #keep-sorted start
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./hyprpanel.nix
    ./notifications.nix
    ./search.nix
    ./wallpaper.nix
    #keep-sorted end
  ];

  # home.pointerCursor = {
  #   x11.enable = lib.mkForce true;
  #   hyprcursor = {
  #     enable = true;
  #     size = 24;
  #   };
  # };
}
