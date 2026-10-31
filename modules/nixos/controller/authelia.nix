_: {
  flake.modules.nixos.authelia =
    { config, ... }:
    {
      age.secrets = {
        authelia-jwt-secret = {
          file = ../../../secrets/authelia-jwt-secret.age;
          owner = "authelia-main";
        };
        authelia-session-secret = {
          file = ../../../secrets/authelia-session-secret.age;
          owner = "authelia-main";
        };
        authelia-storage-encryption-key = {
          file = ../../../secrets/authelia-storage-encryption-key.age;
          owner = "authelia-main";
        };
        authelia-oidc-issuer-key = {
          file = ../../../secrets/authelia-oidc-issuer-key.age;
          owner = "authelia-main";
        };
        authelia-oidc-hmac-secret = {
          file = ../../../secrets/authelia-oidc-hmac-secret.age;
          owner = "authelia-main";
        };
        lldap-admin-password.file = ../../../secrets/lldap-admin-password.age;
      };

      services.authelia.instances.main = {
        enable = true;
        secrets = {
          jwtSecretFile = config.age.secrets.authelia-jwt-secret.path;
          sessionSecretFile = config.age.secrets.authelia-session-secret.path;
          storageEncryptionKeyFile = config.age.secrets.authelia-storage-encryption-key.path;
          oidcIssuerPrivateKeyFile = config.age.secrets.authelia-oidc-issuer-key.path;
          oidcHmacSecretFile = config.age.secrets.authelia-oidc-hmac-secret.path;
        };
        settings = {
          theme = "auto";
          server = {
            address = "tcp://0.0.0.0:9091";
            # Default 4 KiB overflows (431) on large leftover cookies
            buffers.read = 16384;
          };
          log.level = "info";
          # Per-client admission, replacing Keycloak's client-restriction flow.
          identity_providers.oidc.authorization_policies = {
            grafana = {
              default_policy = "deny";
              rules = [
                {
                  policy = "two_factor";
                  subject = [ "group:grafana_admin" ];
                }
              ];
            };
            qui = {
              default_policy = "deny";
              rules = [
                {
                  policy = "two_factor";
                  subject = [ "group:media_admin" ];
                }
              ];
            };
            komga = {
              default_policy = "deny";
              rules = [
                {
                  policy = "two_factor";
                  subject = [ "group:media" ];
                }
              ];
            };
          };
          # Authelia has no global consent default, so apply one here: every client is
          # first-party, so skip the consent screen unless a client requires it
          identity_providers.oidc.clients = map (client: { consent_mode = "implicit"; } // client) [
            {
              client_id = "grafana";
              client_name = "Grafana";
              # Plaintext: secrets/grafana-authelia-oidc-secret.age
              client_secret = "$pbkdf2-sha512$310000$sTAjsjm7SrioziU52CjMkQ$CC6M2OrmwOmwZvjiHen2g7bO5rLGAncezy6yV.rAIhkg8hKEkp2.JCeFf9uot84khLq2xjw9DTwD0fjq8F94Sg";
              public = false;
              authorization_policy = "grafana";
              require_pkce = true;
              pkce_challenge_method = "S256";
              redirect_uris = [
                "https://grafana.rdatar.com/login/generic_oauth"
                "http://10.10.1.13:3000/login/generic_oauth"
              ];
              scopes = [
                "openid"
                "profile"
                "email"
                "groups"
              ];
              response_types = [ "code" ];
              grant_types = [ "authorization_code" ];
              token_endpoint_auth_method = "client_secret_basic";
              userinfo_signed_response_alg = "none";
            }
            {
              client_id = "qui";
              client_name = "Qui";
              # Plaintext: QUI__OIDC_CLIENT_SECRET in secrets/qui-env.age
              client_secret = "$pbkdf2-sha512$310000$.6NJkIGCOogMAZ6FvCYuHw$lxFOGZAGD5GhsxUA1XXgqJdCnkjd2dZyQto9c9WZj/rxhz.9pa6CO2Tn6wnxRvuEBoh9vjsOlN0NgHbxnrJyow";
              public = false;
              # Qui is single-user: anyone this policy admits gets full access.
              authorization_policy = "qui";
              # PKCE is used if Qui sends it, not required.
              require_pkce = false;
              redirect_uris = [ "https://torrent.rdatar.com/api/auth/oidc/callback" ];
              scopes = [
                "openid"
                "profile"
                "email"
              ];
              response_types = [ "code" ];
              grant_types = [ "authorization_code" ];
              token_endpoint_auth_method = "client_secret_basic";
              userinfo_signed_response_alg = "none";
            }
            {
              client_id = "komga";
              client_name = "Komga";
              # Plaintext: secrets/komga-authelia-oidc-env.age (home-media)
              client_secret = "$pbkdf2-sha512$310000$Y7yw4uW.eppYBCmzluTtRQ$qggOUHVH5dl2h/BL18rMyy.X05NNjvnE8KHH4rAoEeEM3xHGtRjKlfVAoPoox4Hb6hONQ.A13LuBQuOgydEo7g";
              public = false;
              authorization_policy = "komga";
              # Spring Security does not send PKCE for confidential clients by default.
              require_pkce = false;
              redirect_uris = [
                "https://books.datars.org/login/oauth2/code/authelia"
                "http://10.10.1.11:25600/login/oauth2/code/authelia"
              ];
              scopes = [
                "openid"
                "profile"
                "email"
              ];
              response_types = [ "code" ];
              grant_types = [ "authorization_code" ];
              token_endpoint_auth_method = "client_secret_basic";
              userinfo_signed_response_alg = "none";
            }
          ];
          totp.issuer = "rdatar.com";
          webauthn = {
            disable = false;
            display_name = "Homelab SSO";
            enable_passkey_login = true;
            # A passkey verified by biometrics/PIN satisfies two_factor rules on its own.
            # Experimental in 4.39; to be superseded by AMR-based access control policies.
            experimental_enable_passkey_uv_two_factors = true;
            selection_criteria = {
              discoverability = "required";
              user_verification = "preferred";
            };
          };
          identity_validation.elevated_session = {
            require_second_factor = true;
            skip_second_factor = true;
          };
          authentication_backend = {
            refresh_interval = "1m";
            ldap = {
              implementation = "lldap";
              address = "ldap://127.0.0.1:3890";
              base_dn = "dc=rdatar,dc=com";
              user = "uid=admin,ou=people,dc=rdatar,dc=com";
            };
          };
          session = {
            name = "authelia_session";
            expiration = "12h";
            inactivity = "4h";
            remember_me = "30d";
            cookies = [
              {
                domain = "rdatar.com";
                authelia_url = "https://auth.rdatar.com";
                default_redirection_url = "https://home.rdatar.com";
              }
              {
                domain = "datars.org";
                authelia_url = "https://login.datars.org";
                default_redirection_url = "https://watch.datars.org";
              }
            ];
          };
          storage.local.path = "/var/lib/authelia-main/db.sqlite3";
          # Real mail for one-time codes and password resets, through the same iCloud
          # account as mail.nix. iCloud only accepts verified aliases as the sender.
          notifier.smtp = {
            address = "submission://smtp.mail.me.com:587"; # STARTTLS required
            username = "rohandatar@icloud.com";
            sender = "Homelab SSO <admin@datars.org>";
            # A mail outage must not take down sign-in for every app.
            disable_startup_check = true;
          };
          access_control = {
            default_policy = "deny";
            rules = [
              {
                domain = [
                  "*.media.rdatar.com"
                ];
                policy = "two_factor";
                subject = [
                  "group:media_admin"
                ];
              }
              {
                domain = [ "*.datars.org" ];
                policy = "one_factor";
              }
            ];
          };
        };
      };

      systemd.services.authelia-main = {
        after = [ "lldap.service" ];
        wants = [ "lldap.service" ];
        serviceConfig.LoadCredential = [
          "ldap-password:${config.age.secrets.lldap-admin-password.path}"
          # iCloud app-specific password, declared by the mail aspect (root-owned).
          "smtp-password:${config.age.secrets.smtp-password.path}"
        ];
        environment = {
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/ldap-password";
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "%d/smtp-password";
        };
      };

      networking.firewall.interfaces.br0.allowedTCPPorts = [ 9091 ];
    };
}
