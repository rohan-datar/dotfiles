{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./intel.nix
  ];

  options.olympus.system.cpu = mkOption {
    type = types.nullOr (
      types.enum [
        "intel"
      ]
    );
    default = null;
  };
}
