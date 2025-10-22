{
  lib,
  config,
  ...
}:
let
  cfg = config.olympus.services;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.olympus.services.homepage = {
    enable = mkEnableOption "Enable homepage dashboard";
  };

  config = mkIf cfg.homepage.enable {
    age.secrets = {
      homepage-env = {
        file = ../../../secrets/homepage-env.age;
        owner = "root";
        group = "users";
        mode = "400";
      };
    };

    services.homepage-dashboard = {
      enable = true;
      openFirewall = true;
      allowedHosts = "10.10.1.11:8082,home.rdatar.com";

      settings = {
        title = "Homelab";
        headerStyle = "boxed";
        color = "slate";
      };

      widgets = [
        {
          datetime = {
            format = {
              timeStyle = "short";
              dateStyle = "short";
              hour12 = "true";
            };
          };
        }
        {
          search = {
            provider = "custom";
            url = "https://startpage.com/sp/search?q=";
            target = "_blank";
            suggestionUrl = "https://www.startpage.com/osuggestions?q=";
            showSearchSuggestions = true;
          };
        }
        {
          resources = {
            cpu = true;
            disk = "/";
            memory = true;
          };
        }
      ];

      services = [
        {
          "Arrs" = [
            {
              "Sonarr" = {
                icon = "sonarr.png";
                href = "https://tv.rdatar.com/";
                widgets = [
                  {
                    type = "sonarr";
                    url = "http://localhost:8989/";
                    key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
                  }
                ];
              };
            }
            {
              "Radarr" = {
                icon = "radarr.png";
                href = "https://movie.rdatar.com/";
                widgets = [
                  {
                    type = "radarr";
                    url = "http://localhost:7878/";
                    key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
                  }
                ];
              };
            }
            {
              "Transmission" = {
                icon = "transmission.png";
                href = "https://torrent.rdatar.com/";
                widgets = [
                  {
                    type = "transmission";
                    url = "http://localhost:9091/transmission/rpc";
                    username = "";
                    password = "{{HOMEPAGE_VAR_TRANSMISSION_PWD}}";
                  }
                ];
              };
            }
            {
              "Prowlarr" = {
                icon = "prowlarr.png";
                href = "http://10.10.1.11:9696/";
                widgets = [
                  {
                    type = "prowlarr";
                    url = "http://localhost:9696/";
                    key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
                  }
                ];
              };
            }
            {
              "Bazarr" = {
                icon = "bazarr.png";
                href = "http://10.10.1.11:6767/";
                widgets = [
                  {
                    type = "bazarr";
                    url = "http://localhost:6767/";
                    key = "{{HOMEPAGE_VAR_BAZARR_KEY}}";
                  }
                ];
              };
            }
          ];
        }
        {
          "Media" = [
            {
              "Jellyfin" = {
                icon = "jellyfin.png";
                href = "https://watch.rdatar.com/";
                widgets = [
                  {
                    type = "jellyfin";
                    url = "http://localhost:8096/";
                    key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                  }
                ];
              };
            }
            {
              "Jellyseerr" = {
                icon = "jellyseerr.png";
                href = "https://lib.rdatar.com/";
                widgets = [
                  {
                    type = "jellyseerr";
                    url = "http://localhost:5055/";
                    key = "{{HOMEPAGE_VAR_JELLYSEERR_KEY}}";
                  }
                ];
              };
            }
          ];
        }
        {
          "Infrastructure" = [
            {
              "TrueNAS" = {
                icon = "truenas.png";
                href = "https://store.rdatar.com/";
                widgets = [
                  {
                    type = "truenas";
                    url = "http://10.10.1.10/";
                    key = "{{HOMEPAGE_VAR_TRUENAS_KEY}}";
                  }
                ];
              };
            }
            {
              "Adguard" = {
                icon = "adguard-home.png";
                href = "https://dns.rdatar.com/";
                widgets = [
                  {
                    type = "adguard";
                    url = "http://10.10.0.1:8080/";
                    username = "rdatar";
                    password = "{{HOMEPAGE_VAR_ADGUARD_PWD}}";
                  }
                ];
              };
            }
            {
              "Opnsense" = {
                icon = "opnsense.png";
                href = "https://opnsense.localdomain:8443/";
                widgets = [
                  {
                    type = "opnsense";
                    url = "https://10.10.0.1:8443/";
                    username = "{{HOMEPAGE_VAR_OPNSENSE_USER}}";
                    password = "{{HOMEPAGE_VAR_OPNSENSE_PWD}}";
                  }
                ];
              };
            }
            {
              "OpenWRT" = {
                icon = "openwrt.png";
                href = "https://10.10.0.2/";
              };
            }
          ];
        }
      ];
    };

    # Create the environment file from agenix secrets before starting homepage
    # systemd.services.homepage-dashboard.environment = {
    #   HOMEPAGE_VAR_SONARR_KEY = "${config.age.secrets.sonarrApiKey.path}";
    #   HOMEPAGE_VAR_RADARR_KEY = "${config.age.secrets.radarrApiKey.path}";
    #   HOMEPAGE_VAR_PROWLARR_KEY = "${config.age.secrets.prowlarrApiKey.path}";
    #   HOMEPAGE_VAR_BAZARR_KEY = "${config.age.secrets.bazarrApiKey.path}";
    #   HOMEPAGE_VAR_JELLYFIN_KEY = "${config.age.secrets.jellyfinApiKey.path}";
    #   HOMEPAGE_VAR_JELLYSEERR_KEY = "${config.age.secrets.jellyseerrApiKey.path}";
    #   HOMEPAGE_VAR_TRUENAS_KEY = "${config.age.secrets.truenasApiKey.path}";
    #   HOMEPAGE_VAR_ADGUARD_PWD = "${config.age.secrets.adguardPass.path}";
    #   HOMEPAGE_VAR_OPNSENSE_USER = "${config.age.secrets.opnsenseUser.path}";
    #   HOMEPAGE_VAR_OPNSENSE_PWD = "${config.age.secrets.opnsensePass.path}";
    #   HOMEPAGE_VAR_TRANSMISSION_PWD = "${config.age.secrets.transmissionPwd.path}";
    # };
  };
}
