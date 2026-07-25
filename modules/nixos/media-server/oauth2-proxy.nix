_: {
  # Forward-auth backend for the *.media.rdatar.com vhosts (see media-ingress).
  # Lives on home-media because the host that runs the services fronts them.
  flake.modules.nixos.media-oauth2-proxy =
    { config, ... }:
    {
      # OAUTH2_PROXY_CLIENT_SECRET (Keycloak client `homelab-proxy`) +
      # OAUTH2_PROXY_COOKIE_SECRET.
      age.secrets.oauth2-proxy-env.file = ../../../secrets/oauth2-proxy-env.age;

      services.oauth2-proxy = {
        enable = true;
        provider = "keycloak-oidc";
        clientID = "homelab-proxy";
        oidcIssuerUrl = "https://auth.datars.org/realms/homelab";
        keyFile = config.age.secrets.oauth2-proxy-env.path;
        # Loopback only — Caddy is the only client, so no firewall hole.
        httpAddress = "http://127.0.0.1:4180";
        reverseProxy = true;
        setXauthrequest = true; # emit X-Auth-Request-User/-Email for copy_headers
        email.domains = [ "*" ]; # access control happens in Keycloak, not here
        trustedProxyIP = [ "127.0.0.1/32" ]; # only local Caddy may set X-Forwarded-*
        cookie = {
          domain = ".media.rdatar.com"; # one login for every protected vhost
          secure = true;
        };
        extraConfig = {
          whitelist-domain = ".media.rdatar.com"; # allowed post-login redirect targets
          code-challenge-method = "S256"; # PKCE
          # Keycloak is the only provider — go straight there instead of showing
          # the /oauth2/sign_in button page first.
          skip-provider-button = true;
        };
      };
    };
}
