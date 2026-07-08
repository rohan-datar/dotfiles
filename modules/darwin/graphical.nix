{ self, ... }:
{
  flake.modules.darwin.graphical = {
    imports = [
      self.modules.darwin.ai
      self.modules.darwin.fonts
      self.modules.darwin.graphical-packages
      self.modules.darwin.home-manager
    ];
  };
}
