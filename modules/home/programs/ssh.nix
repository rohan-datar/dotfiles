{ config, ... }:
{
  programs.ssh = {
    # we're only using this config in graphical environments
    inherit (config.olympus.aspects.graphical) enable;
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
}
