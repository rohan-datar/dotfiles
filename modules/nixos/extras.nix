{ inputs, ... }:
{
  flake.modules.nixos.extras = {
    imports = [
      inputs.agenix.nixosModules.default
      inputs.disko.nixosModules.disko
    ];
  };
}
