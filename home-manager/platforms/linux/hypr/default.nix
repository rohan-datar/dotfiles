{...}: {
  imports = [
    ./hyprland.nix
    ./networkmanager.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpanel.nix
  ];

  services.dunst.enable = true;
  programs.fuzzel = {
    enable = true;
  };

  services.wpaperd.enable = {
    enable = true;
    settings = {
      default = {
        path = "~/.local/share/backgrounds/";
        duration = "30m";
      };
    };
  };

  # services.hyprpaper = {
  #   enable = true;
  #   settings = {
  #     preload = [
  #       "~/.local/share/backgrounds/nixos-wallpaper-catppuccin-mocha.png"
  #     ];

  #     wallpaper = [
  #       ",~/.local/share/backgrounds/nixos-wallpaper-catppuccin-mocha.png"
  #       # ",~/.local/share/backgrounds/Cloudsnight.jpg"
  #     ];
  #   };
  # };
}
