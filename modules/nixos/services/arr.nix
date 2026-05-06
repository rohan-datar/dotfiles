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
    age.secrets.wgconf.file = ../../../secrets/AirVPN-America-WG.conf.age;

    vpnNamespaces.wg.portMappings = lib.mkForce [ ];

    nixarr = {
      enable = true;

      vpn = {
        enable = true;
        wgConf = config.age.secrets.wgconf.path;
        accessibleFrom = [ "10.10.0.0/19" ];
      };

      mediaDir = "/mnt/media";

      jellyfin = {
        enable = true;
        openFirewall = true;
      };
      seerr = {
        enable = true;
        openFirewall = true;
      };
      bazarr = {
        enable = true;
        openFirewall = true;
      };
      prowlarr = {
        enable = true;
        openFirewall = true;
      };
      radarr = {
        enable = true;
        openFirewall = true;
      };
      sonarr = {
        enable = true;
        openFirewall = true;
      };

      qbittorrent = {
        enable = true;
        vpn.enable = true;
        openFirewall = true;
        peerPort = 21209;
        qui.enable = true;
        extraConfig = {
          BitTorrent = {
            "Session\\DefaultSavePath" = "/mnt/media/torrents";
            "Session\\TempPath" = "/mnt/media/torrents/.incomplete";
            "Session\\TempPathEnabled" = true;
          };
          Preferences = {
            "Downloads\\SavePath" = "/mnt/media/torrents";
            "Downloads\\TempPath" = "/mnt/media/torrents/.incomplete";
            "Downloads\\TempPathEnabled" = true;
            "Downloads\\ScanDirsV2" = builtins.toJSON {
              "/mnt/media/torrents/.watch" = 0;
            };
            "WebUI\\Password_PBKDF2" =
              ''"@ByteArray(AcS/eSauZc8rMTFhenysTA==:woLHoXoRKxq/v3SyNB3HAL+SZKz1icLlHVzRrV54m8mJOdlt/xu9M2n+slobkmSb81m/G7h8o+/bzR4Ozn+BhQ==)"'';
          };
        };
      };

      transmission = {
        enable = false;
        flood.enable = true;
        vpn.enable = true;
        peerPort = 21209;
      };

      recyclarr = {
        enable = true;

        configuration = {
          sonarr = {
            series = {
              base_url = "http://localhost:8989";
              api_key = "!env_var SONARR_API_KEY";
            };
          };
          radarr = {
            movies = {
              base_url = "http://localhost:7878";
              api_key = "!env_var RADARR_API_KEY";
            };
          };
        };
      };
    };

    systemd.services.jellyfin.environment = {
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
