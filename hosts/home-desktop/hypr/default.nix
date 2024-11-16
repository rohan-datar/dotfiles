{...}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
  ];

  programs.wofi.enable = true;
}
