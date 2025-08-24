{
  lib,
  self,
  self',
  config,
  inputs,
  inputs',
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

    users = genAttrs config.users.users (name: {
      imports = [ ./${name} ];
    });

    extraSpecialArgs = {
      inherit
        self
        self'
        inputs
        inputs'
        ;
    };

    sharedModules = [ (self + /modules/home/default.nix) ];
  };
}
