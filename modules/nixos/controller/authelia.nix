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
        # Shared with lldap's DynamicUser: retain root ownership and pass a credential.
        lldap-admin-password.file = ../../../secrets/lldap-admin-password.age;
      };

      services.authelia.instances.main = {
        enable = true;
        secrets = {
          jwtSecretFile = config.age.secrets.authelia-jwt-secret.path;
          sessionSecretFile = config.age.secrets.authelia-session-secret.path;
          storageEncryptionKeyFile = config.age.secrets.authelia-storage-encryption-key.path;
        };
        settings = {
          theme = "auto";
          server.address = "tcp://0.0.0.0:9091";
          log.level = "info";
          totp.issuer = "rdatar.com";
          webauthn = {
            disable = false;
            display_name = "Homelab SSO";
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
          notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
          access_control = {
            default_policy = "deny";
            rules = [
              {
                domain = [
                  "*.media.rdatar.com"
                  "net.rdatar.com"
                  "dns.rdatar.com"
                  "store.rdatar.com"
                  "portal.rdatar.com"
                ];
                policy = "one_factor";
                # admins is the planned role; lldap_admin is LLDAP's built-in role.
                # Explicit admin identities avoid a first-test group-mapping lockout.
                subject = [
                  "group:admins"
                  "group:lldap_admin"
                  "user:rdatar"
                  "user:admin"
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
        ];
        environment.AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/ldap-password";
      };

      networking.firewall.interfaces.br0.allowedTCPPorts = [ 9091 ];
    };
}
