{ config, mkIf, ... }:
let
  inherit (config.olympus.system) gpu;
in
{
  nixpkgs.config = {
    # I want to install packages that are not FOSS sometimes
    allowUnfree = true;
    # A funny little hack to make sure that *everything* is permitted
    allowUnfreePredicate = _: true;

    # this list also does not include actually useful sets like pkgsi686Linux
    # however this can also break some packages from building
    allowVariants = true;

    # If a package is broken, I don't want it
    allowBroken = false;
    # But occasionally we need to install some anyway so we can predicated those
    # these are usually packages like electron because discord and others love
    # to take their sweet time updating it
    permittedInsecurePackages = [
      # dependency graph of our issue, starting from the highest level package we depend on
    ];

    # I allow packages that are not supported by my system
    allowUnsupportedSystem = true;

    # cudaSupport = if (gpu == "nvidia") then true else false;
  };
}
