{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.agenix-template.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.stylix.nixosModules.stylix
  ];
}
