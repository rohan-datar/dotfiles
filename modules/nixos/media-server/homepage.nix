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
              headerStyle = "boxedWidgets";
              theme = "dark";
              color = "slate";
              iconStyle = "theme";
              statusStyle = "dot";
              useEqualHeights = true;
              hideVersion = true;
              disableIndexing = true;

              layout = {
                Applications = {
                  icon = "mdi-apps";
                  style = "row";
                  columns = 4;
                };
                Arrs = {
                  icon = "mdi-download";
                  style = "row";
                  columns = 3;
                };
                Hosts.icon = "mdi-server";
                Identity.icon = "mdi-shield-lock";
                Network.icon = "mdi-lan";
                Observability.icon = "mdi-chart-line";
              };
            };

            widgets = [
              {
                resources = {
                  label = "home-media";
                  cpu = true;
                  memory = true;
                  cputemp = true;
                  uptime = true;
                  units = "metric";
                };
              }
              {
                resources = {
                  label = "Storage";
                  # /mnt/media is the NFS export from home-nas. If the NAS is down
                  # this tile errors on its own rather than taking the row with it.
                  disk = [
                    "/"
                    "/mnt/media"
                  ];
                };
              }
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
            ];

            services = [
              {
                "Arrs" = [
                  {
                    "Sonarr" = {
                      icon = "sonarr.png";
                      href = "https://tv.media.rdatar.com/";
                      description = "TV series automation";
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
                      description = "Movie automation";
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
                      description = "Downloads, inside the VPN namespace";
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
                      description = "Indexer manager for the arrs";
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
                      description = "Subtitles for Sonarr and Radarr";
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
                      description = "Book automation and ingest";
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
                      description = "Movies, TV and music";
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
                      href = "https://catalog.datars.org/";
                      description = "Request movies and TV";
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
                      description = "Comics and ebooks, Kobo sync";
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
                      description = "Scanned document archive";
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
                "Network" = [
                  {
                    "Opnsense" = {
                      icon = "opnsense.png";
                      href = "https://net.rdatar.com/";
                      description = "Router, firewall, reverse proxy";
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
                    "Adguard" = {
                      icon = "adguard-home.png";
                      href = "https://dns.rdatar.com/";
                      description = "DNS filtering and LAN records";
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
                    "Netgear Nighthawk" = {
                      icon = "netgear.png";
                      href = "https://10.10.0.2/";
                      description = "Wi-Fi access point";
                      siteMonitor = "http://10.10.0.2/";
                    };
                  }
                  {
                    "OpenWRT" = {
                      icon = "openwrt.png";
                      href = "https://10.10.0.4/";
                      description = "Wi-Fi access point";
                      siteMonitor = "http://10.10.0.4/";
                    };
                  }
                ];
              }
              {
                "Identity" = [
                  {
                    "Keycloak" = {
                      icon = "keycloak.png";
                      href = "https://auth.datars.org";
                      description = "OIDC for the homelab realm";
                      siteMonitor = "https://auth.datars.org";
                    };
                  }
                  {
                    "LLDAP" = {
                      icon = "lldap.png";
                      href = "https://ldap.rdatar.com";
                      description = "Directory behind Keycloak";
                      siteMonitor = "https://ldap.rdatar.com";
                    };
                  }
                ];
              }
              {
                "Observability" = [
                  {
                    "Grafana" = {
                      icon = "grafana.png";
                      href = "http://grafana.rdatar.com/";
                      description = "Prometheus dashboards";
                      widgets = [
                        {
                          type = "grafana";
                          version = 2; # admin/stats shape changed after Grafana 10.4
                          url = "http://10.10.1.13:3000";
                          username = "{{HOMEPAGE_VAR_GRAFANA_USER}}";
                          password = "{{HOMEPAGE_VAR_GRAFANA_PWD}}";
                        }
                      ];
                    };
                  }
                  {
                    "Gatus" = {
                      icon = "gatus.png";
                      href = "https://status.datars.org/";
                      description = "Uptime checks and alerting";
                      widgets = [
                        {
                          type = "gatus";
                          url = "http://10.10.1.13:8081";
                        }
                      ];
                    };
                  }
                  {
                    "ntfy" = {
                      icon = "ntfy.png";
                      href = "https://ntfy.datars.org/";
                      description = "Push notifications";
                      widgets = [
                        {
                          type = "ntfy";
                          url = "http://10.10.1.13:2586";
                          topic = "homelab";
                          key = "{{HOMEPAGE_VAR_NTFY_TOKEN}}";
                        }
                      ];
                    };
                  }
                ];
              }
              {
                "Hosts" = [
                  {
                    "NAS" = {
                      icon = "cockpit.png";
                      href = "https://store.rdatar.com";
                      description = "home-nas, Cockpit";
                      siteMonitor = "https://store.rdatar.com";
                    };
                  }
                  {
                    "Home Controller" = {
                      icon = "cockpit.png";
                      href = "https://controller.rdatar.com";
                      description = "home-controller, Cockpit";
                      siteMonitor = "https://controller.rdatar.com";
                    };
                  }
                  {
                    "HomeAssistant" = {
                      icon = "home-assistant.png";
                      href = "https://ha.rdatar.com";
                      description = "Home automation, VM on the controller";
                      siteMonitor = "https://ha.rdatar.com";
                    };
                  }
                ];
              }
            ];
          };
        }
      )
    ];
  };
}
