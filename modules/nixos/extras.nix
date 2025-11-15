{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.niri.nixosModules.niri
  ];
}
