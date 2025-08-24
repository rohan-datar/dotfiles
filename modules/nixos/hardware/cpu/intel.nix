{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.olympus.system) cpuVendor;
in
{
  # I only have devices with intel CPUs running nixos
  config = mkIf (cpuVendor.cpu == "intel" || cpuVendor.cpu == "vm-intel") {
    hardware.cpu.intel.updateMicrocode = true;

    boot = {
      kernelModules = [ "kvm-intel" ];
      kernelParams = [
        "i915.fastboot=1"
        "enable_gvt=1"
      ];
    };
  };
}
