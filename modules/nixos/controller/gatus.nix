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
      # Every endpoint pushes on the same policy, so name the list once.
      ntfy = [ { type = "ntfy"; } ];

    in
    {
      # Direct probes of the media apps come
      imports = [ self.modules.nixos.media-probes ];
      age.secrets.gatus-env.file = ../../../secrets/gatus-env.age;

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

          endpoints = lib.mkMerge [
            (lib.mkBefore [
              # --- Identity ---
              {
                name = "keycloak";
                group = "identity";
                interval = "60s";
                url = "${topology.identity.issuerUrl}/.well-known/openid-configuration";
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
                url = "tcp://${topology.hosts.home-controller.lanAddress}:3890";
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
                url = "http://${topology.hosts.home-media.lanAddress}:5055";
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
            ])
            (lib.mkAfter [
              # --- Infrastructure ---
              {
                name = "nas-smb";
                group = "infra";
                interval = "120s";
                url = "tcp://${topology.hosts.home-nas.lanAddress}:445";
                conditions = [ "[CONNECTED] == true" ];
                alerts = ntfy;
              }
              {
                name = "warpgate-direct";
                group = "infra";
                interval = "60s";
                url = "tcp://${topology.hosts.home-media.lanAddress}:8888";
                conditions = [ "[CONNECTED] == true" ];
                alerts = ntfy;
              }
              {
                name = "home-assistant";
                group = "infra";
                interval = "120s";
                url = "http://${topology.hosts.home-assistant.lanAddress}:8123";
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
            ])
          ];
        };
      };

      # LAN only; the public status.datars.org vhost lives on OPNsense.
      networking.firewall.interfaces.br0.allowedTCPPorts = [ 8081 ];
    };
}
