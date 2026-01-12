{ lib, config, ... }:
let
  inherit (lib) mkOption optional;
  inherit (lib.types) listOf str;
in
{
  options.olympus.system = {
    users = mkOption {
      type = listOf str;
      default = [ "rdatar" ];
      description = "A list of users that you wish to declare as your non-system users.       ";
    };
  };

  config = {
    warnings = optional (config.olympus.system.users == [ ]) ''
      You have not added any users to be supported by your system. You may end up with an unbootable system!

      Consider setting {option}`config.olympus.system.users` in your configuration
    '';
  };
}
