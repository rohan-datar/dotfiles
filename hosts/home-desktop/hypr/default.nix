{...}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
    ./swaync.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "~/.local/share/backgrounds/Cloudsnight.jpg"
      ];

      wallpaper = [
        ",~/.local/share/backgrounds/Cloudsnight.jpg"
      ];
    };
  };
}
