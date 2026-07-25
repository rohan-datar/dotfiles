{ inputs, ... }:
{
  flake.modules.nixos.extras = {
    imports = [
      inputs.ragenix.nixosModules.default
      inputs.disko.nixosModules.disko
    ];
  };
}
