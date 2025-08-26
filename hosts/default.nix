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

    hosts = {
      zeus = {
        class = "nixos";
      };
      apollo = {
        arch = "aarch64";
        class = "darwin";
      };
    };
  };
}
