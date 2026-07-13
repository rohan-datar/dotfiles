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
    path = ../hosts;

    perClass = class: {
      modules = [
        self.modules.${class}.default
      ];
    };

    shared = {
      modules = [
        self.modules.generic.shared
      ];
    };

    hosts = {
      home-desktop = {
        class = "nixos";
      };
      Rohans-MacBook = {
        arch = "aarch64";
        class = "darwin";
      };
      home-media = {
        class = "nixos";
      };
    };
  };
}
