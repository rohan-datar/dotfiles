{...}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
    ./networkmanager.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./wlogout.nix
  ];

  services.swaync.enable = true;

  home.file.".config/ashell".source = ./ashell;

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
