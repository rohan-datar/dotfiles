{
  flake.modules.nixos.intel-gpu =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.variables = lib.mkIf config.hardware.graphics.enable {
        VDPAU_DRIVER = "va_gl";
        LIBVA_DRIVER_NAME = "iHD";
      };

      environment.systemPackages = [ pkgs.intel-gpu-tools ];

      # i915 kernel module
      boot.initrd.kernelModules = [ "i915" ];
      # we enable modesetting since this is recomeneded for intel gpus
      services.xserver.videoDrivers = [ "modesetting" ];

      # OpenCL support and VAAPI
      hardware.graphics = {
        extraPackages = builtins.attrValues {
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
    };
}
