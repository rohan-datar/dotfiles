{
  flake.modules.nixos.nvidia =
    { pkgs, ... }:
    {
      # NOTE: Don't turn this back on globally, override individual packages if they need CUDA support
      # `nixpkgs.config.cudaSupport = true`

      environment.systemPackages = [
        pkgs.nvtopPackages.nvidia
        pkgs.vulkan-tools
        pkgs.vulkan-loader
        pkgs.vulkan-validation-layers
        pkgs.vulkan-extension-layer
        pkgs.libva
        pkgs.libva-utils
      ];

      services.xserver.videoDrivers = [ "nvidia" ];

      # Enables the Nvidia's experimental framebuffer device
      # fix for the imaginary monitor that does not exist
      boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __GL_GSYNC_ALLOWED = "1";
        __GL_VRR_ALLOWED = "0";
        NVD_BACKEND = "direct";
      };

      hardware.nvidia = {
        modesetting.enable = true;

        powerManagement = {
          enable = true;
          finegrained = false;
        };

        # dont use the open drivers by default
        open = false;

        # adds nvidia-settings to pkgs, so useless on nixos
        nvidiaSettings = false;
      };

      hardware.graphics = {
        extraPackages = [ pkgs.nvidia-vaapi-driver ];
      };
    };
}
