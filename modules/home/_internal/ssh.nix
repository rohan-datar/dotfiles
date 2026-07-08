_: {
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
      };
    };
  };
}
