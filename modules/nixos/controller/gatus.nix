_: {
  # Availability monitoring + the family-facing status page. Port 8081 because
  # Keycloak already owns 8080 on this host. Gatus is the lab's only availability
  # alerter — there is no Alertmanager; smartd/ZED mail hardware faults directly.
  flake.modules.nixos.gatus =
    { config, ... }:
    let
      # Every endpoint mails on the same policy, so name the list once.
      email = [ { type = "email"; } ];

      # Unauthenticated GET of a forward-auth vhost must redirect to Keycloak.
      # One probe proves Caddy + wildcard cert + oauth2-proxy end to end.
      ingress = name: {
        inherit name;
        group = "media-ingress";
        interval = "300s";
        url = "https://${name}.media.rdatar.com";
        client.follow-redirects = false;
        conditions = [
          "[STATUS] == 302"
          "[CERTIFICATE_EXPIRATION] > 240h"
        ];
        alerts = email;
      };
    in
    {
      # GATUS_SMTP_PASSWORD=<icloud app-specific password>. Gatus interpolates
      # ${VAR} from this file into the config at startup.
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

          alerting.email = {
            from = "status@rdatar.com";
            username = "rohandatar@icloud.com";
            password = "\${GATUS_SMTP_PASSWORD}";
            host = "smtp.mail.me.com";
            port = 587;
            to = "me@rdatar.com";
            default-alert = {
              # 3x60s of failure before mailing: kills flap noise.
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
              alerts = email;
            }
            {
              name = "lldap";
              group = "identity";
              interval = "60s";
              url = "tcp://10.10.1.13:3890";
              conditions = [ "[CONNECTED] == true" ];
              alerts = email;
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
              alerts = email;
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
              alerts = email;
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
              alerts = email;
            }
            {
              name = "seerr";
              group = "public";
              interval = "120s";
              url = "http://10.10.1.11:5055";
              conditions = [ "[STATUS] < 400" ];
              alerts = email;
            }
            {
              name = "qui";
              group = "public";
              interval = "120s";
              # Direct LAN hit for now; swap to the public name once qui gets one.
              url = "https://torrent.rdatar.com:5252";
              conditions = [ "[STATUS] < 400" ];
              alerts = email;
            }

            # --- Forward-auth tier ---
            (ingress "tv")
            (ingress "movie")
            (ingress "trackers")
            (ingress "subtitles")
            (ingress "shelfmark")

            # --- Infrastructure ---
            {
              name = "nas-smb";
              group = "infra";
              interval = "120s";
              url = "tcp://10.10.1.10:445";
              conditions = [ "[CONNECTED] == true" ];
              alerts = email;
            }
            {
              name = "home-assistant";
              group = "infra";
              interval = "120s";
              url = "http://10.10.1.12:8123";
              conditions = [ "[STATUS] < 400" ];
              alerts = email;
            }
            {
              name = "router";
              group = "infra";
              interval = "60s";
              url = "icmp://10.10.0.1";
              conditions = [ "[CONNECTED] == true" ];
              alerts = email;
            }
          ];
        };
      };

      # LAN only; the public status.datars.org vhost lives on OPNsense.
      networking.firewall.interfaces.br0.allowedTCPPorts = [ 8081 ];
    };
}
