{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkEnableOption
    ;

  cfg = config.olympus.services.printing;
in {
  options.olympus.services.printing = {
    enable = mkEnableOption "printing";
  };

  config = mkIf cfg.enable {
    # enable cups and some drivers for common printers
    services = {
      printing = {
        enable = true;
      };

      # required for network discovery of printers
      avahi = {
        enable = true;
        nssmdns4 = true;
        nssmdns6 = true;
        openFirewall = true;
      };
    };
  };
}
