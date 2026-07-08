{ self, ... }:
{
  flake.modules.darwin.default = {
    imports = [
      self.modules.darwin.brew
      self.modules.darwin.documentation
      self.modules.darwin.extras
      self.modules.darwin.nix
      self.modules.darwin.packages
      self.modules.darwin.shell
      self.modules.darwin.system
    ];
  };
}
