{ self, ... }:
{
  flake.modules.nixos.graphical = {
    imports = [
      self.modules.nixos.ai
      self.modules.nixos.colors
      self.modules.nixos.earlyoom
      self.modules.nixos.flatpak
      self.modules.nixos.fonts
      self.modules.nixos.graphical-packages
      self.modules.nixos.graphical-programs
      self.modules.nixos.home-manager
      self.modules.nixos.hyprland
      self.modules.nixos.login-manager
      self.modules.nixos.logs
      self.modules.nixos.runners
      self.modules.nixos.wayland
      self.modules.nixos.xserver
    ];
  };
}
