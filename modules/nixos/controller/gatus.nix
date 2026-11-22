{
  self,
  lib,
  config,
  ...
}:
let
  topology = config.flake.meta.topology;
in
{
  flake.modules.nixos.gatus =
    { config, ... }:
    let
      # Cluster/identity failure must not depend on in-cluster notifications.
      email = [ { type = "email"; } ];
      ntfy = [ { type = "ntfy"; } ];

    in
    {
      # Direct probes of the media apps come
      imports = [ self.modules.nixos.media-probes ];
      age.secrets.gatus-env.file = ../../../secrets/gatus-env.age;
      age.secrets.gatus-watchdog-env.file = ../../../secrets/gatus-watchdog-env.age;
      systemd.services.gatus.serviceConfig.EnvironmentFile = lib.mkAfter [
        config.age.secrets.gatus-watchdog-env.path
      ];

      services.gatus = {
        enable = true;
        environmentFile = config.age.secrets.gatus-env.path;

        settings = {
          web.port = 8081;
          metrics = true; # scraped by the local Prometheus

          # Survive restarts: without this Gatus keeps history and alert state in
          # memory, so every `just switch` resets the failure counters. The unit
          # already gets StateDirectory=gatus.
          storage = {
            type = "sqlite";
            path = "/var/lib/gatus/data.db";
          };

          # Same independent iCloud transport and sender as europa's native watchdog.
          alerting.email = {
            from = "homelab@rdatar.com";
            username = "rohandatar@icloud.com";
            password = "\${GATUS_SMTP_PASSWORD}";
            host = "smtp.mail.me.com";
            port = 587;
            to = "me@rdatar.com";
            default-alert = {
              failure-threshold = 3;
              success-threshold = 2;
              send-on-resolved = true;
            };
          };

          # Everyday alerts use the stable HTTPS vhost, currently served by k3s.
          alerting.ntfy = {
            url = "https://ntfy.datars.org";
            topic = "homelab";
            token = "\${GATUS_NTFY_TOKEN}";
            default-alert = {
              failure-threshold = 3;
              success-threshold = 2;
              send-on-resolved = true;
            };
          };

          external-endpoints = [
            {
              name = "monitoring-watchdog";
              group = "cluster";
              token = "\${GATUS_WATCHDOG_TOKEN}";
              heartbeat.interval = "6m";
              alerts = [
                {
                  type = "email";
                  failure-threshold = 1;
                  success-threshold = 1;
                  send-on-resolved = true;
                }
              ];
            }
          ];

          endpoints = lib.mkMerge [
            (lib.mkBefore [
              # --- Identity ---
              {
                # Family portal and OIDC issuer.
                name = "authelia";
                group = "identity";
                interval = "60s";
                url = "${topology.identity.baseUrl}/api/health";
                conditions = [
                  "[STATUS] == 200"
                  "[CERTIFICATE_EXPIRATION] > 240h"
                ];
                alerts = email;
              }
              {
                # Forward-auth portal for *.rdatar.com (cookie domains need their own portal).
                name = "authelia-rdatar";
                group = "identity";
                interval = "60s";
                url = "https://auth.rdatar.com/api/health";
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
                url = "tcp://${topology.hosts.callisto.lanAddress}:3890";
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
                # Grafana runs in k3s (oort-cloud apps/grafana) behind OPNsense Caddy → the Cilium Gateway VIP.
                name = "grafana";
                group = "infra";
                interval = "120s";
                url = "https://grafana.rdatar.com/api/health";
                conditions = [
                  "[STATUS] == 200"
                  "[BODY].database == ok"
                ];
                alerts = ntfy;
              }
              {
                # Seerr runs in k3s (oort-cloud apps/media/seerr.pkl) behind OPNsense Caddy.
                name = "seerr";
                group = "public";
                interval = "120s";
                url = "https://catalog.datars.org/api/v1/status";
                conditions = [
                  "[STATUS] == 200"
                  "[CERTIFICATE_EXPIRATION] > 240h"
                ];
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

              # --- Internally accessible endpoints ---
              {
                # Probe Paperless through the internal Cilium Gateway, independently of Caddy.
                name = "paperless-app";
                group = "infra";
                interval = "120s";
                url = "http://10.10.2.20/accounts/login/";
                headers.Host = "docs.datars.org";
                conditions = [ "[STATUS] == 200" ];
                alerts = ntfy;
              }
              {
                # OPNsense Caddy + Authelia forward auth: unauthenticated -> 302 to login.
                name = "media-forward-auth";
                group = "media-ingress";
                interval = "300s";
                url = "https://tv.media.rdatar.com";
                client.ignore-redirect = true;
                conditions = [
                  "[STATUS] == 302"
                  "[CERTIFICATE_EXPIRATION] > 240h"
                ];
                alerts = email;
              }
            ])
            (lib.mkAfter [
              # --- Infrastructure ---
              {
                name = "ceres-smb";
                group = "infra";
                interval = "120s";
                url = "tcp://${topology.hosts.ceres.lanAddress}:445";
                conditions = [ "[CONNECTED] == true" ];
                alerts = ntfy;
              }
              {
                name = "homeassistant";
                group = "infra";
                interval = "120s";
                url = "http://${topology.hosts.homeassistant.lanAddress}:8123";
                conditions = [ "[STATUS] < 400" ];
                alerts = ntfy;
              }
              {
                name = "router";
                group = "infra";
                interval = "60s";
                url = "icmp://${topology.gatewayAddress}";
                conditions = [ "[CONNECTED] == true" ];
                alerts = ntfy;
              }
              {
                # Host-down checks for the k3s nodes: ganymede's 2026-11-04
                # hardware fault went unnoticed for 43 hours.
                name = "io-host";
                group = "infra";
                interval = "60s";
                url = "icmp://${topology.hosts.io.lanAddress}";
                conditions = [ "[CONNECTED] == true" ];
                alerts = ntfy;
              }
              {
                name = "ganymede-host";
                group = "infra";
                interval = "60s";
                url = "icmp://${topology.hosts.ganymede.lanAddress}";
                conditions = [ "[CONNECTED] == true" ];
                alerts = ntfy;
              }
              {
                name = "europa-host";
                group = "infra";
                interval = "60s";
                url = "icmp://${topology.hosts.europa.lanAddress}";
                conditions = [ "[CONNECTED] == true" ];
                alerts = ntfy;
              }
              {
                name = "k3s-api";
                group = "infra";
                interval = "60s";
                url = "tcp://${topology.k3sApiAddress}:6443";
                conditions = [ "[CONNECTED] == true" ];
                alerts = email;
              }
            ])
          ];
        };
      };

      # LAN only; the public status.datars.org vhost lives on OPNsense.
      networking.firewall.interfaces.br0.allowedTCPPorts = [ 8081 ];
    };
}
