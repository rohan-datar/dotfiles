{ self, lib, ... }:
{
  flake.modules.generic.shared =
    { _class, ... }:
    {
      imports =
        lib.optionals (_class == "nixos") [
          self.modules.nixos.base
          self.modules.nixos.nixpkgs
          self.modules.nixos.variables
        ]
        ++ lib.optionals (_class == "darwin") [
          self.modules.darwin.base
          self.modules.darwin.nixpkgs
          self.modules.darwin.variables
        ];
    };
}
