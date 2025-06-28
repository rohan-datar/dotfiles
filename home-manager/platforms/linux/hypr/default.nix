{...}: {
  imports = [
    ./hyprland.nix
    ./networkmanager.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpanel.nix
  ];

  # services.dunst.enable = true;
  programs.fuzzel = {
    enable = true;
  };

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
