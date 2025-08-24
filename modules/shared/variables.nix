{
  lib,
  _class,
  config,
  ...
}: let
  inherit (lib) mkOption;
  inherit (lib.types) str;
in {
  options.olympus.environment.flakePath = mkOption {
    type = str;
    default = "";
    description = "The path to the configuration";
  };

  config.environment.variables = {
    SYSTEMD_PAGERSECURE = "true";

    # Some programs like `nh` use the FLAKE env var to determine the flake path
    FLAKE = config.olympus.environment.flakePath;
    NH_FLAKE = config.olympus.environment.flakePath;
  };
}
