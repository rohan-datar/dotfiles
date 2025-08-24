{
  self,
  inputs,
  ...
}:
{
  imports = [
    inputs.easy-hosts.flakeModule
  ];

  config.easyHosts = {
    perClass = class: {
      modules = [
        "${self}/modules/${class}/default.nix"
      ];

      hosts = {
        home-desktop = { };
        home-media = { };
        macbook = {
          arch = "aarch64";
          class = "darwin";
        };
      };
    };
  };
}
