{lib, ...}: let
  inherit (lib) mkOption types;
in {
  imports = [
    # keep-sorted start
    ./intel.nix
    ./nvidia.nix
    # keep-sorted end
  ];

  options.olympus.system.gpu = mkOption {
    type = types.nullOr (
      types.enum [
        "intel"
        "nvidia"
      ]
    );
    default = null;
    description = "The manufacturer of the primary system gpu";
  };
}
