{ self, inputs, ... }:
let
  settings = {
    verbose = true;
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "bak";

    extraSpecialArgs = {
      inherit
        self
        inputs
        ;
    };

    sharedModules = [
      self.modules.homeManager.default
      inputs.nix-index-database.homeModules.nix-index
      inputs.agenix.homeManagerModules.default
      inputs.vicinae.homeManagerModules.default
    ];
  };
in
{
  flake.modules.nixos.home-manager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager = settings;
  };

  flake.modules.darwin.home-manager = {
    imports = [ inputs.home-manager.darwinModules.home-manager ];
    home-manager = settings;
  };
}
