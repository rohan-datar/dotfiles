{
  self,
  inputs,
  ...
}:
{
  imports = [
    inputs.easy-hosts.flakeModule
  ];

  config.easy-hosts = {
    perClass = class: {
      modules = [
        "${self}/modules/${class}/default.nix"
      ];
    };

    shared = {
      modules = [
        "${self}/modules/shared/default.nix"
      ];
    };

    perTag =
      tag:
      if tag == "full" then
        { specialArgs.neovimPkg = "full"; }
      else if tag == "minimal" then
        { specialArgs.neovimPkg = "minimal"; }
      else
        { };

    hosts = {
      zeus = {
        class = "nixos";
        tags = [ "full" ];
      };
      apollo = {
        arch = "aarch64";
        class = "darwin";
        tags = [ "full" ];
      };
      dionysus = {
        class = "nixos";
        tags = [ "minimal" ];
      };
    };
  };
}
