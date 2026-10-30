_:
let
  issuer = "https://auth.rdatar.com";
in
{
  flake.modules.nixos.grafana =
    { config, ... }:
    {
      age.secrets.grafana-oidc-secret = {
        file = ../../../secrets/grafana-authelia-oidc-secret.age;
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

      # `declarativePlugins` is deliberately unset: setting it flips
      # `settings.plugins.preinstall_disabled` to true, which drops the six
      # plugins nixpkgs preinstalls, so it would cost more than it buys.
      services.grafana = {
        enable = true;

        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
            # Must match the base of the Authelia client's redirect URI.
            root_url = "https://grafana.rdatar.com";
          };

          security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";

          "auth.generic_oauth" = {
            enabled = true;
            name = "Authelia";
            client_id = "grafana";
            client_secret = "$__file{${config.age.secrets.grafana-oidc-secret.path}}";
            scopes = "openid profile email groups";
            auth_url = "${issuer}/api/oidc/authorization";
            token_url = "${issuer}/api/oidc/token";
            api_url = "${issuer}/api/oidc/userinfo";
            auth_style = "InHeader"; # matches token_endpoint_auth_method client_secret_basic
            use_pkce = true;
            login_attribute_path = "preferred_username";
            name_attribute_path = "name";
            groups_attribute_path = "groups";
            # Admin iff in the lldap group; everyone else who can log in is a Viewer.
            role_attribute_path = "contains(groups[*], 'grafana_admin') && 'Admin' || 'Viewer'";
            allow_sign_up = true;
          };
        };

        provision = {
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              uid = "prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:9090";
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
