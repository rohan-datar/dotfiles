_: {
  flake.modules.nixos.gatus =
    { config, ... }:
    let
      # Every endpoint pushes on the same policy, so name the list once.
      ntfy = [ { type = "ntfy"; } ];

      # Direct liveness probe of an *arr app's unauthenticated /ping endpoint,
      # bypassing Caddy and oauth2-proxy entirely.
      arr-app = name: port: {
        inherit name;
        group = "media-ingress";
        interval = "120s";
        url = "http://10.10.1.11:${toString port}/ping";
        conditions = [ "[STATUS] == 200" ];
        alerts = ntfy;
      };
    in
    {
      age.secrets.gatus-env.file = ../../../secrets/gatus-env.age;

      services.gatus = {
        enable = true;
        environmentFile = config.age.secrets.gatus-env.path;

        settings = {
          web.port = 8081;
          metrics = true; # scraped by the local Prometheus

          # Survive restarts: without this Gatus keeps history and alert state in
          # memory, so every `nx switch` resets the failure counters. The unit
          # already gets StateDirectory=gatus.
          storage = {
            type = "sqlite";
            path = "/var/lib/gatus/data.db";
          };

          alerting.ntfy = {
            url = "http://127.0.0.1:2586";
            topic = "homelab";
            token = "\${GATUS_NTFY_TOKEN}";
            default-alert = {
              failure-threshold = 3;
              success-threshold = 2;
              send-on-resolved = true;
            };
          };

          endpoints = [
            # --- Identity ---
            {
              name = "keycloak";
              group = "identity";
              interval = "60s";
              url = "https://auth.datars.org/realms/homelab/.well-known/openid-configuration";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 240h"
              ];
              alerts = ntfy;
            }
            {
              name = "lldap";
              group = "identity";
              interval = "60s";
              url = "tcp://10.10.1.13:3890";
              conditions = [ "[CONNECTED] == true" ];
              alerts = ntfy;
            }

            # --- Public vhosts. ---
            {
              name = "paperless";
              group = "public";
              interval = "120s";
              url = "https://docs.datars.org";
              conditions = [
                "[STATUS] < 400"
                "[CERTIFICATE_EXPIRATION] > 240h"
              ];
              alerts = ntfy;
            }
            {
              name = "komga";
              group = "public";
              interval = "120s";
              # If Komga 1.25 404s here, fall back to plain `/`.
              url = "https://books.datars.org/";
              conditions = [
                "[STATUS] < 400"
                "[CERTIFICATE_EXPIRATION] > 240h"
              ];
              alerts = ntfy;
            }
            {
              name = "jellyfin";
              group = "public";
              interval = "120s";
              url = "https://watch.datars.org/health";
              conditions = [
                "[STATUS] == 200"
                "[BODY] == Healthy"
              ];
              alerts = ntfy;
            }
            {
              name = "seerr";
              group = "public";
              interval = "120s";
              url = "http://10.10.1.11:5055";
              conditions = [ "[STATUS] < 400" ];
              alerts = ntfy;
            }
            {
              name = "qui";
              group = "public";
              interval = "120s";
              url = "https://torrent.rdatar.com";
              conditions = [ "[STATUS] < 400" ];
              alerts = ntfy;
            }
            {
              name = "warpgate";
              group = "public";
              interval = "60s";
              url = "https://portal.rdatar.com";
              client.ignore-redirect = true;
              conditions = [
                "[STATUS] == 307"
                "[CERTIFICATE_EXPIRATION] > 240h"
              ];
              alerts = ntfy;
            }

            # --- Internally accessible endpoints ---
            {
              name = "oauth2-proxy";
              group = "media-ingress";
              interval = "300s";
              url = "https://tv.media.rdatar.com";
              client.ignore-redirect = true;
              conditions = [
                "[STATUS] == 302"
                "[CERTIFICATE_EXPIRATION] > 240h"
              ];
              alerts = ntfy;
            }

            # --- Apps behind the media.* vhosts, probed directly ---
            (arr-app "sonarr-app" 8989)
            (arr-app "radarr-app" 7878)
            (arr-app "prowlarr-app" 9696)

            # Bazarr has no unauthenticated ping endpoint; TCP is enough.
            {
              name = "bazarr-app";
              group = "media-ingress";
              interval = "120s";
              url = "tcp://10.10.1.11:6767";
              conditions = [ "[CONNECTED] == true" ];
              alerts = ntfy;
            }

            # Shelfmark likewise has no ping endpoint.
            {
              name = "shelfmark-app";
              group = "media-ingress";
              interval = "120s";
              url = "tcp://10.10.1.11:8084";
              conditions = [ "[CONNECTED] == true" ];
              alerts = ntfy;
            }

            # --- Infrastructure ---
            {
              name = "nas-smb";
              group = "infra";
              interval = "120s";
              url = "tcp://10.10.1.10:445";
              conditions = [ "[CONNECTED] == true" ];
              alerts = ntfy;
            }
            {
              name = "warpgate-direct";
              group = "infra";
              interval = "60s";
              url = "tcp://10.10.1.11:8888";
              conditions = [ "[CONNECTED] == true" ];
              alerts = ntfy;
            }
            {
              name = "home-assistant";
              group = "infra";
              interval = "120s";
              url = "http://10.10.1.12:8123";
              conditions = [ "[STATUS] < 400" ];
              alerts = ntfy;
            }
            {
              name = "router";
              group = "infra";
              interval = "60s";
              url = "icmp://10.10.0.1";
              conditions = [ "[CONNECTED] == true" ];
              alerts = ntfy;
            }
          ];
        };
      };

      # LAN only; the public status.datars.org vhost lives on OPNsense.
      networking.firewall.interfaces.br0.allowedTCPPorts = [ 8081 ];
    };
}
