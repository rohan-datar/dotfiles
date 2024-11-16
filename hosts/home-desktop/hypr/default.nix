{...}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
    ./swaync.nix
  ];

  services.swaync = {
    enable = true;
  };
}
