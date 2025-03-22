{...}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
    ./networkmanager.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  services.swaync.enable = true;

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "~/.local/share/backgrounds/nixos-wallpaper-catppuccin-mocha.png"
        # "~/.local/share/backgrounds/Cloudsnight.jpg"
      ];

      wallpaper = [
        ",~/.local/share/backgrounds/nixos-wallpaper-catppuccin-mocha.png"
        # ",~/.local/share/backgrounds/Cloudsnight.jpg"
      ];
    };
  };
}
