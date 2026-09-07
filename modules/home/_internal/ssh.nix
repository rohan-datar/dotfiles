{ config, ... }:
let
  topology = config.flake.meta.topology;
in
{
  flake.modules.homeManager.ssh = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "uwgcloud" = {
          HostName = "104.198.64.179";
          User = "rdatar";
          IdentityFile = "~/.ssh/id_rsa";
        };

        "homemedia" = {
          HostName = "media.rdatar.com";
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
        "homenas" = {
          HostName = topology.hosts.home-nas.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
        "homecontroller" = {
          HostName = topology.hosts.home-controller.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
