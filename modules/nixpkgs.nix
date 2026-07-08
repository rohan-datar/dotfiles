let
  nixpkgsConfig = {
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowVariants = true;
      allowBroken = false;
      allowUnsupportedSystem = false;
    };
  };
in
{
  flake.modules.nixos.nixpkgs = nixpkgsConfig;
  flake.modules.darwin.nixpkgs = nixpkgsConfig;
}
