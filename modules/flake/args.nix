# see
# https://github.com/nix-systems/nix-systems
# https://github.com/isabelroses/dotfiles/blob/main/modules/flake/args.nix
{ inputs, ... }:
{
  # set the output systems for this flake
  # nixpkgs 26.11 dropped x86_64-darwin support; the only Darwin host is aarch64.
  systems = builtins.filter (s: s != "x86_64-darwin") (import inputs.systems);

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
      };
    };
}
