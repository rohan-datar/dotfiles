{
  lib,
  config,
  ...
}:
let
  inherit (lib) elem mkIf;
in
{
  config = mkIf (elem "rdatar" config.olympus.system.users) {
    users.users.rdatar = {
      openssh.authorizedKeys.keys = [
        # laptop keys
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYDkyHobLUDOAkNqHxcOkVScdCclKG6m6Az7OT/NAd3"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDD5ZECdU1ZRd1dRj0QOD5SYO+Ocgr8ONQ5PyV1R7ZazAh0e4VYAsyJKLZbnuyO7H3eBy6fTc/ykyW1+FvfX8eCvMR4Z1qNBv2sY9xVF89Yow1jBGzCu5xMqnEbidhxcpfkwN7G0PRBO+fir4U83AmQ9TVQ1E52mvi3XgRR22fEXGYgPTfM36C2s2J2D+/VCM/P5emi6lRfLu+e8kfWy+fM9tQEnKHQitJpS037yhsRny3QPdxPMFbVWxNHfHzebj14E/n8jvVW372tET9B6T28W6u2BjE+g+7jLtpYT9eduPtjDyI6HJapmbZlnLXPpbpNbTdWQSqMnX2rGeZHb/QPMO4dPCWEWUnmsBW4VeDNV0M97+RNMrvoBpGeuM955T6B+L5ulGLjkSvhtr9IA/kXuCoCWdsEPPAz/26DB7nRWPKrKwbHnZ5Uu0D7cJXwVeQuU4UHBX6qPJ2p5n8GUGHLGSTrQOdFejIYw9IWmU16dz2SdhDMU9OJaDme7LKWUQ8="

        # desktop keys
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2wVTZEDwBCIvmTEiKj3pUmhOR+W9qknzbVTXhM25h6"
      ];
    };
  };
}
