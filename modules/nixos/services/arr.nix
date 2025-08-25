{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.olympus.services;
  inherit (lib) mkEnableOption mkIf;
in
{
  imports = [
    inputs.nixarr.nixosModules.default
  ];

  options.olympus.services.arr = {
    enable = mkEnableOption "Enable media applications";
  };

  config = mkIf cfg.arr.enable {
    # TODO: maybe make this host-specific?
    age.secrets.wgconf.file = ./secrets/AirVPN-America-WG.conf.age;

    nixarr = {
      enable = true;

      vpn = {
        enable = true;
        wgConf = config.age.secrets.wgconf.path;
        accessibleFrom = [ "10.10.0.0/19" ];
      };

      mediaDir = "/mnt/media";

      jellyfin.enable = true;
      jellyseerr.enable = true;
      bazarr.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;

      transmission = {
        enable = true;
        flood.enable = true;
        vpn.enable = true;
        peerPort = 21209;
      };

      # recyclarr = {
      #   enable = true;

      #   configuration =  {
      #     sonarr = {
      #       series = {
      #         base_url = "http://localhost:8989";
      #         api_key = "!env_var SONARR_API_KEY";
      #       };
      #     };
      #     radarr = {
      #       movies = {
      #         base_url = "http://localhost:7878";
      #         api_key = "!env_var RADARR_API_KEY";
      #       };
      #     };
      #   };
      # };
    };

    systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD"; # Or "i965" if using older driver
  };
}
