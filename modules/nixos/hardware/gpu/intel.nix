{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf attrValues;
  inherit (config.olympus.system) gpu;
in
{
  config = mkIf (gpu == "intel") {
    # i915 kernel module
    boot.initrd.kernelModules = [ "i915" ];
    # we enable modesetting since this is recomeneded for intel gpus
    services.xserver.videoDrivers = [ "modesetting" ];

    # OpenCL support and VAAPI
    hardware.graphics = {
      extraPackages = attrValues {
        inherit (pkgs)
          libva-vdpau-driver
          intel-media-driver
          vaapiVdpau
          intel-compute-runtime
          vpl-gpu-rt
          intel-media-sdk
          ;

        intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
      };
    };

    olympus.packages = [ pkgs.intel-gpu-tools ];

    environment.variables = mkIf (config.hardware.graphics.enable) {
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVWER_NAME = "iHD";
    };
  };
}
