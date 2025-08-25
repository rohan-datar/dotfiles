# put terminfo onto our servers so the ssh experience is better
{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = lib.mkIf config.services.openssh.enable {
    olympus.packages = {
      inherit (pkgs.ghostty) terminfo;
    };
  };
}
