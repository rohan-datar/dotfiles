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

        "europa" = {
          HostName = topology.hosts.europa.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
        "homemedia" = {
          HostName = topology.hosts.europa.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
        "ceres" = {
          HostName = topology.hosts.ceres.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
        "callisto" = {
          HostName = topology.hosts.callisto.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
        "io" = {
          HostName = topology.hosts.io.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
        "ganymede" = {
          HostName = topology.hosts.ganymede.lanAddress;
          User = "rdatar";
          IdentityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };
}
