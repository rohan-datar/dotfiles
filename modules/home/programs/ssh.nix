{
  programs.ssh = {
    matchBlocks = {
      "uwgcloud" = {
        hostname = "104.198.64.179";
        user = "rdatar";
        identityFile = "~/.ssh/id_rsa";
      };

      "homemedia" = {
        hostname = "media.rdatar.com";
        user = "rdatar";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
