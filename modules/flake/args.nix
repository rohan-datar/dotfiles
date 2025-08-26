# see
# https://github.com/nix-systems/nix-systems
# https://github.com/isabelroses/dotfiles/blob/main/modules/flake/args.nix
{ inputs, ... }:
{
  # set the output systems for this flake
  systems = import inputs.systems;

  perSystem =
    { system, ... }:
    {
      # this is what controls how packages in the flake are built
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
        overlays = [ ];
      };
    };
}
