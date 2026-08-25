_: {
  flake.modules.nixos.media-books =
    { config, pkgs, ... }:
    {
      # SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_KEYCLOAK_CLIENT_SECRET
      # (Keycloak client `komga`).
      age.secrets.komga-oidc-env.file = ../../../secrets/komga-oidc-env.age;

      nixarr = {
        komga.enable = true;
        shelfmark = {
          enable = true;
          # Bind to all interfaces so Gatus (home-controller) can probe the app
          # directly; the firewall rule below restricts 8084 to the controller.
          # The public vhost probe can't detect upstream death, because Caddy +
          # oauth2-proxy answer with a 302 before ever touching Shelfmark.
          host = "0.0.0.0";
        };
      };

      services.shelfmark.environment = {
        AUTH_METHOD = "proxy";
        PROXY_AUTH_USER_HEADER = "X-Auth-Request-User";
        PROXY_AUTH_LOGOUT_URL = "https://shelfmark.media.rdatar.com/oauth2/sign_out";
        INGEST_DIR = "${config.nixarr.mediaDir}/library/books";
      };

      services.komga.settings.spring.security.oauth2.client = {
        registration.keycloak = {
          provider = "keycloak";
          client-id = "komga";
          client-name = "Keycloak";
          scope = "openid,email";
          authorization-grant-type = "authorization_code";
          redirect-uri = "{baseUrl}/{action}/oauth2/code/{registrationId}";
          client-authentication-method = "client_secret_basic";
        };
        provider.keycloak = {
          issuer-uri = "https://auth.datars.org/realms/homelab";
          user-name-attribute = "sub";
        };
      };

      systemd.services.komga = {
        environment.KOMGA_OAUTH2ACCOUNTCREATION = "true";
        serviceConfig.EnvironmentFile = config.age.secrets.komga-oidc-env.path;
      };

      # Komga ships the JAR, which (unlike the Docker image) does not bundle
      # kepubify — without it there is no EPUB→KEPUB conversion for Kobo sync.
      environment.systemPackages = [ pkgs.kepubify ];

      # Reachable only from the LAN side, for the router's Caddy to proxy.
      networking.firewall.interfaces.enp1s0.allowedTCPPorts = [ 25600 ];

      # Shelfmark itself: only the controller may connect for its liveness probe.
      networking.firewall.extraInputRules = ''
        iifname "enp1s0" ip saddr 10.10.1.13 tcp dport 8084 accept comment "gatus -> shelfmark"
      '';
    };
}
