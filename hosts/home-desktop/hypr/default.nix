{...}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
  ];

  gtk.catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "blue";
    size = "standard";
    gnomeShellTheme = true;
    icon = {
      enable = true;
      flavor = "mocha";
      accent = "blue";
    };
  };
}
