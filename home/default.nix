{
  lib,
  self,
  self',
  config,
  inputs,
  inputs',
  neovimPkg,
  ...
}:
let
  inherit (lib) genAttrs;
in
{
  home-manager = {
    verbose = true;
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "bak";

    users = genAttrs config.olympus.system.users (name: {
      imports = [ ./${name} ];
    });

    extraSpecialArgs = {
      inherit
        self
        self'
        inputs
        inputs'
        neovimPkg
        ;
    };

    sharedModules = [
      (self + /modules/home/default.nix)
      inputs.nix-index-database.homeModules.nix-index
    ];
  };
}
