{
  flake.modules.nixos.homepage = {
    imports = [
      (
        { config, ... }:
        {
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

            environmentFiles = [ config.age.secrets.homepage-env.path ];

            settings = {
              title = "Homelab";
              headerStyle = "boxed";
              color = "slate";
              disableIndexing = true;
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
                      href = "https://tv.media.rdatar.com/";
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
                      href = "https://movie.media.rdatar.com/";
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
                    "qBittorrent" = {
                      icon = "qbittorrent.png";
                      href = "https://torrent.rdatar.com/";
                      widgets = [
                        {
                          type = "qbittorrent";
                          url = "http://192.168.15.1:8085";
                          username = "{{HOMEPAGE_VAR_QBITTORRENT_USER}}";
                          password = "{{HOMEPAGE_VAR_QBITTORRENT_PWD}}";
                        }
                      ];
                    };
                  }
                  {
                    "Prowlarr" = {
                      icon = "prowlarr.png";
                      href = "http://trackers.media.rdatar.com/";
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
                      href = "http://subtitles.media.rdatar.com/";
                      widgets = [
                        {
                          type = "bazarr";
                          url = "http://localhost:6767/";
                          key = "{{HOMEPAGE_VAR_BAZARR_KEY}}";
                        }
                      ];
                    };
                  }
                  {
                    "Shelfmark" = {
                      icon = "shelfmark.png";
                      href = "https://shelfmark.media.rdatar.com/";
                    };
                  }
                ];
              }
              {
                "Applications" = [
                  {
                    "Jellyfin" = {
                      icon = "jellyfin.png";
                      href = "https://watch.datars.org/";
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
                      href = "https://catlog.datars.org/";
                      widgets = [
                        {
                          type = "seerr";
                          url = "http://localhost:5055/";
                          key = "{{HOMEPAGE_VAR_JELLYSEERR_KEY}}";
                        }
                      ];
                    };
                  }
                  {
                    "Komga" = {
                      icon = "komga.png";
                      href = "https://books.datars.org/";
                      widgets = [
                        {
                          type = "komga";
                          url = "http://localhost:25600/";
                          key = "{{HOMEPAGE_VAR_KOMGA_KEY}}";
                        }
                      ];
                    };
                  }
                  {
                    "Paperless" = {
                      icon = "paperless.png";
                      href = "https://docs.datars.org";
                      widgets = [
                        {
                          type = "paperlessngx";
                          url = "http://10.10.1.10:28981";
                          key = "{{HOMEPAGE_VAR_PAPERLESS_KEY}}";
                        }
                      ];
                    };
                  }
                ];
              }
              {
                "Infrastructure" = [
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
                      href = "https://net.rdatar.com/";
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
                    "Netgear Nighthawk" = {
                      icon = "netgear.png";
                      href = "https://10.10.0.2/";
                    };
                  }
                  {
                    "OpenWRT" = {
                      icon = "openwrt.png";
                      href = "https://10.10.0.4/";
                    };
                  }
                  {
                    "HomeAssistant" = {
                      icon = "home-assistant.png";
                      href = "https://ha.rdatar.com";
                    };
                  }
                  {
                    "NAS" = {
                      icon = "cockpit.png";
                      href = "https://store.rdatar.com";
                    };
                  }
                  {
                    "Home Controller" = {
                      icon = "cockpit.png";
                      href = "https://controller.rdatar.com";
                    };
                  }
                  {
                    "Keycloak" = {
                      icon = "keycloak.png";
                      href = "https://auth.datars.org";
                    };
                  }
                  {
                    "LLDAP" = {
                      icon = "lldap.png";
                      href = "https://ldap.rdatar.com";
                    };
                  }
                  # {
                  #   "Speedtest Tracker" = {
                  #     icon = "speedtest-tracker.png";
                  #     href = "https://10.10.1.10:30221";
                  #     widgets = [
                  #       {
                  #         type = "speedtest";
                  #         url = "http://10.10.1.10:30220";
                  #         version = 2;
                  #         key = "{{HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY}}";
                  #       }
                  #     ];
                  #   };
                  # }
                ];
              }
            ];
          };
        }
      )
    ];
  };
}
