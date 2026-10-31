_:
let
  # Authelia (home-controller) replaces Keycloak as Komga's OIDC provider.
  issuer = "https://auth.rdatar.com";
in
{
  flake.modules.nixos.media-books =
    { config, pkgs, ... }:
    {
      # SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AUTHELIA_CLIENT_SECRET
      # (Authelia client `komga`).
      age.secrets.komga-oidc-env.file = ../../../secrets/komga-authelia-oidc-env.age;

      nixarr = {
        komga.enable = true;
        shelfmark = {
          enable = true;
          # Bind to all interfaces so OPNsense Caddy can proxy it and Gatus
          # (home-controller) can probe it; media-probe-access restricts 8084 to
          # those two. The public vhost probe can't detect upstream death, because
          # Caddy + Authelia answer with a 302 before ever touching Shelfmark.
          host = "0.0.0.0";
        };
      };

      services.shelfmark.environment = {
        AUTH_METHOD = "proxy";
        # Copied from Authelia's forward-auth response by OPNsense Caddy.
        PROXY_AUTH_USER_HEADER = "Remote-User";
        PROXY_AUTH_LOGOUT_URL = "https://auth.rdatar.com/logout";
        INGEST_DIR = "${config.nixarr.mediaDir}/library/books";
      };

      services.komga.settings.spring.security.oauth2.client = {
        registration.authelia = {
          provider = "authelia";
          client-id = "komga";
          client-name = "Authelia";
          scope = "openid,profile,email";
          authorization-grant-type = "authorization_code";
          redirect-uri = "{baseUrl}/{action}/oauth2/code/{registrationId}";
          client-authentication-method = "client_secret_basic";
        };
        provider.authelia = {
          issuer-uri = issuer;
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
    };
}
