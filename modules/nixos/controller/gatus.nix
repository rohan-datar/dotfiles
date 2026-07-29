_: {
  # Availability monitoring + the family-facing status page. Port 8081 because
  # Keycloak already owns 8080 on this host. Gatus is the lab's only availability
  # alerter — there is no Alertmanager; smartd/ZED mail hardware faults directly.
  #
  # Alerts push to the local ntfy (the `ntfy` aspect). Email is deliberately not
  # a second provider here: the only failure this instance cannot report is one
  # that takes this host down, and the home-media watchdog already mails for
  # exactly that. A second channel would just double every ordinary outage.
  flake.modules.nixos.gatus =
    { config, ... }:
    let
      # Every endpoint pushes on the same policy, so name the list once.
      ntfy = [ { type = "ntfy"; } ];

      # Unauthenticated GET of a forward-auth vhost must redirect to Keycloak.
      # One probe proves Caddy + wildcard cert + oauth2-proxy end to end.
      ingress = name: {
        inherit name;
        group = "media-ingress";
        interval = "300s";
        url = "https://${name}.media.rdatar.com";
        client.ignore-redirect = true;
        conditions = [
          "[STATUS] == 302"
          "[CERTIFICATE_EXPIRATION] > 240h"
        ];
        alerts = ntfy;
      };
    in
    {
      # GATUS_NTFY_TOKEN=<ntfy access token>. Gatus interpolates ${VAR} from this
      # file into the config at startup. The same file also carries
      # GATUS_SMTP_PASSWORD for the home-media watchdog, which is unused here —
      # this instance pushes and does not mail.
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
            # ntfy runs on this host: post straight to it instead of hairpinning
            # out through the public vhost. Gatus POSTs to the server root with
            # the topic in the JSON body, so this must NOT include the topic.
            url = "http://127.0.0.1:2586";
            topic = "homelab";
            # Must be an ntfy access token (`tk_…`) — Gatus refuses to start on
            # anything else, and it is sent as a Bearer header.
            token = "\${GATUS_NTFY_TOKEN}";
            default-alert = {
              # 3x60s of failure before pushing: kills flap noise.
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
