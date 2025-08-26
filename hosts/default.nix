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
      home-desktop = {
        class = "nixos";
      };
      macbook = {
        arch = "aarch64";
        class = "darwin";
      };
    };
  };
}
