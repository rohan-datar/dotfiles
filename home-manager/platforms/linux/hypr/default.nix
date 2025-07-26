{lib, ...}: {
  imports = [
    ./hyprland.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpanel.nix
  ];

  services.dunst.enable = true;
  programs.fuzzel = {
    enable = true;
  };

  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        path = "~/.local/share/backgrounds/";
        duration = "30m";
      };
    };
  };

  home.pointerCursor = {
    x11 = lib.mkForce true;
    hyprcursor = {
      enable = true;
      size = 24;
    };
  };
}
