{
  lib,
  config,
  ...
}:
let
  cfg = config.olympus.aspects;
in
{
  config = lib.mkIf cfg.graphical.enable {
    # some settings for wayland
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";

      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "0";
      WLR_DRM_NO_ATOMIC = "1";

      GDK_SCALE = "2";

      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      NVD_BACKEND = "direct";
    };
  };
}
