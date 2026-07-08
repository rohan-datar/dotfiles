{ self, ... }:
{
  flake.modules.nixos.default = {
    imports = [
      self.modules.nixos.command-not-found
      self.modules.nixos.console
      self.modules.nixos.documentation
      self.modules.nixos.extras
      self.modules.nixos.firmware
      self.modules.nixos.localization
      self.modules.nixos.nix
      self.modules.nixos.oomd
      self.modules.nixos.packages
      self.modules.nixos.serial
      self.modules.nixos.shell
      self.modules.nixos.size
      self.modules.nixos.terminfo
      self.modules.nixos.time
    ];
  };
}
