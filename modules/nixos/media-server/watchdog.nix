{ config, ... }:
let
  topology = config.flake.meta.topology;
in
{
  # Who watches home-controller? A second, tiny Gatus lives here and watches only
  # the things the main Gatus cannot report on: itself and its host. Loopback
  # only — it has no UI worth exposing, it exists to send mail. Port 8181 because
  # homepage owns 8082.
  #
  # Accepted failure mode: if home-media and home-controller die together nobody
  # mails. That is what the family texting you is for.
  flake.modules.nixos.media-watchdog =
    { config, ... }:
    let
      email = [ { type = "email"; } ];
    in
    {
      # Same GATUS_SMTP_PASSWORD secret as the controller's Gatus.
      age.secrets.gatus-env.file = ../../../secrets/gatus-env.age;

      services.gatus = {
        enable = true;
        environmentFile = config.age.secrets.gatus-env.path;

        settings = {
          web = {
            address = "127.0.0.1";
            port = 8181;
          };

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
              failure-threshold = 3;
              success-threshold = 2;
              send-on-resolved = true;
            };
          };

          endpoints = [
            {
              name = "controller-host";
              url = "icmp://${topology.hosts.home-controller.lanAddress}";
              interval = "60s";
              conditions = [ "[CONNECTED] == true" ];
              alerts = email;
            }
            {
              name = "main-gatus";
              url = "http://${topology.hosts.home-controller.lanAddress}:8081/health";
              interval = "60s";
              conditions = [ "[STATUS] == 200" ];
              alerts = email;
            }
            # The main Gatus pushes through ntfy, so it cannot report ntfy's own
            # death while the host stays up. /v1/health is unauthenticated even
            # under auth-default-access=deny-all, and answers {"healthy":true}.
            {
              name = "ntfy";
              url = "http://${topology.hosts.home-controller.lanAddress}:2586/v1/health";
              interval = "60s";
              conditions = [
                "[STATUS] == 200"
                "[BODY].healthy == true"
              ];
              alerts = email;
            }
            {
              name = "keycloak";
              url = "${topology.identity.issuerUrl}/.well-known/openid-configuration";
              interval = "120s";
              conditions = [ "[STATUS] == 200" ];
              alerts = email;
            }
          ];
        };
      };
    };
}
