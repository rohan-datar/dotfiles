_: {
  # Private tier: LAN/WireGuard only, like the lldap UI — no public vhost.
  # Login is Keycloak OIDC (client `grafana`); the local admin account stays
  # enabled as break-glass, so `disable_login_form` is deliberately unset.
  flake.modules.nixos.grafana =
    { config, ... }:
    {
      # The Keycloak client secret, raw (no KEY= prefix): `$__file{}` below reads
      # the file verbatim. Grafana reads it itself, hence the owner.
      age.secrets.grafana-oidc-secret = {
        file = ../../../secrets/grafana-oidc-secret.age;
        owner = "grafana";
      };

      # `security.secret_key` lost its default in 26.05 and is now asserted to be
      # set via a file provider. It signs datasource secrets in Grafana's DB, so
      # it is generated once and must not be rotated casually — changing it
      # orphans anything already encrypted with the old key.
      age.secrets.grafana-secret-key = {
        file = ../../../secrets/grafana-secret-key.age;
        owner = "grafana";
      };

      services.grafana = {
        enable = true;

        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
            # Must match the base of the Keycloak client's redirect URI.
            root_url = "http://10.10.1.13:3000";
          };

          security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";

          "auth.generic_oauth" = {
            enabled = true;
            name = "Keycloak";
            client_id = "grafana";
            client_secret = "$__file{${config.age.secrets.grafana-oidc-secret.path}}";
            scopes = "openid email profile";
            auth_url = "https://auth.datars.org/realms/homelab/protocol/openid-connect/auth";
            token_url = "https://auth.datars.org/realms/homelab/protocol/openid-connect/token";
            api_url = "https://auth.datars.org/realms/homelab/protocol/openid-connect/userinfo";
            # Admin iff in the lldap group; everyone else who can log in is a Viewer.
            # Needs the client's Group Membership mapper (claim `groups`, full path off).
            role_attribute_path = "contains(groups[*], 'grafana_admin') && 'Admin' || 'Viewer'";
            allow_sign_up = true;
          };
        };

        provision = {
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              # Fixed uid so the committed dashboards can reference it directly
              # instead of going through an import-time `${DS_PROMETHEUS}` input.
              uid = "prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:9091";
              isDefault = true;
            }
          ];

          dashboards.settings.providers = [
            {
              name = "repo";
              options.path = ./grafana-dashboards;
            }
          ];
        };
      };

      networking.firewall.interfaces.br0.allowedTCPPorts = [ 3000 ];
    };
}
