{ inputs, ... }:
{
  flake.modules.nixos.arr = {
    imports = [
      inputs.nixarr.nixosModules.default
      (
        { config, ... }:
        {
          age.secrets.wgconf.file = ../../secrets/AirVPN-America-WG.conf.age;

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
                Preferences = {
                  "WebUI\\Password_PBKDF2" =
                    ''"@ByteArray(AcS/eSauZc8rMTFhenysTA==:woLHoXoRKxq/v3SyNB3HAL+SZKz1icLlHVzRrV54m8mJOdlt/xu9M2n+slobkmSb81m/G7h8o+/bzR4Ozn+BhQ==)"'';
                };
              };
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
        }
      )
    ];
  };
}
