_: {
  # A clientless bastion that hands out browser-based SSH, VNC and
  # HTTP sessions to hosts which stay LAN-only.
  flake.modules.nixos.warpgate =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Warpgate cannot read secrets from the environment or from a file
      # (warp-tech/warpgate#1195), and the nixpkgs module renders `settings`
      # into the world-readable Nix store — so a literal client secret here
      # would leak both into the store and into git. Instead the store copy
      # carries a placeholder, and the real value is substituted into the
      # state-dir copy at start, out of a systemd credential.
      #
      # The substitution has to happen after the module's own ExecStartPre,
      # which rewrites /var/lib/warpgate/config.yaml from the store on every
      # start. Adding a second ExecStartPre is not possible — serviceConfig
      # options conflict rather than merge — so this wraps ExecStart instead,
      # which costs one reconstructed line of upstream logic rather than a copy
      # of its whole init script.
      ssoSecretPlaceholder = "@SSO_CLIENT_SECRET@";
      startWithSsoSecret = pkgs.writeShellScript "warpgate-start" ''
        set -euo pipefail
        umask 077
        secret=$(cat "$CREDENTIALS_DIRECTORY/ssoClientSecret")
        ${pkgs.gnused}/bin/sed -i \
          "s|${ssoSecretPlaceholder}|$secret|" \
          /var/lib/warpgate/config.yaml
        exec ${lib.getExe pkgs.warpgate} --config /var/lib/warpgate/config.yaml run
      '';
    in
    {
      age.secrets.warpgate-sso-secret.file = ../../../secrets/warpgate-sso-secret.age;

      services.warpgate = {
        enable = true;

        settings = {
          http = {
            # Browser SSH, VNC and RDP all ride this listener, so it is the only
            # one that needs to exist. 8888 is upstream's default and is also
            # hardcoded into the nixpkgs module's first-boot `unattended-setup`,
            # so moving it would desync the bootstrap config from this one.
            listen = "[::]:8888";

            external_host = "portal.rdatar.com";

            trust_x_forwarded_headers = true;
          };

          ssh.enable = false;

          sso_providers = [
            {
              name = "keycloak";
              label = "Keycloak";

              auto_create_users = false;

              # Pins the SSO return URL to the public name, so a login started
              # against any other host header cannot redirect the callback.
              return_domain_whitelist = [ "portal.rdatar.com" ];

              provider = {
                type = "custom";
                client_id = "warpgate";
                client_secret = ssoSecretPlaceholder;
                issuer_url = "https://auth.datars.org/realms/homelab";
                # Warpgate matches the OIDC identity to a Warpgate user by
                # email, so `email` is load-bearing, not decorative.
                scopes = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
            }
          ];
        };
      };

      systemd.services.warpgate.serviceConfig = {
        LoadCredential = lib.mkForce "ssoClientSecret:${config.age.secrets.warpgate-sso-secret.path}";
        ExecStart = lib.mkForce startWithSsoSecret;
      };

      # LAN only
      networking.firewall.interfaces.enp1s0.allowedTCPPorts = [ 8888 ];
    };
}
