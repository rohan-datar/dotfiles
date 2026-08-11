_: {
  flake.modules.nixos.lldap =
    { config, ... }:
    {
      age.secrets.lldap-env.file = ../../../secrets/lldap-env.age;
      age.secrets.lldap-admin-password.file = ../../../secrets/lldap-admin-password.age;
      age.secrets.cloudflare-dns-token.file = ../../../secrets/cloudflare-dns-token.age;

      security.acme = {
        acceptTerms = true;
        defaults.email = "me@rdatar.com";
        certs."ldap.rdatar.com" = {
          domain = "ldap.rdatar.com";
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets.cloudflare-dns-token.path;
          group = "lldap-certs";
          reloadServices = [ "lldap.service" ];
        };
      };

      users.groups.lldap-certs.members = [ "lldap" ];

      services.lldap = {
        enable = true;
        environmentFile = config.age.secrets.lldap-env.path;
        environment.LLDAP_LDAP_USER_PASS_FILE = "%d/admin-password";

        # The admin password is applied on first start (empty DB) and may then be
        # changed in the web UI; we deliberately do not force-reset it on every
        # restart, so silence the module's drift warning.
        silenceForceUserPassResetWarning = true;

        settings = {
          ldap_base_dn = "dc=rdatar,dc=com";
          # LDAP for Jellyfin on 10.10.1.11 and Keycloak federation
          ldap_host = "0.0.0.0";
          ldap_port = 3890;
          # LDAPS alongside plain LDAP, using the ACME cert from above.
          ldaps_options = {
            enabled = true;
            port = 6360;
            cert_file = "${config.security.acme.certs."ldap.rdatar.com".directory}/fullchain.pem";
            key_file = "${config.security.acme.certs."ldap.rdatar.com".directory}/key.pem";
          };
          # Admin web UI on the LAN.
          http_host = "0.0.0.0";
          http_port = 17170;
          http_url = "http://10.10.1.13:17170";
          ldap_user_email = "me@rdatar.com";
        };
      };

      # lldap runs as a DynamicUser and reads the password file itself, so the
      # root-owned agenix path is unreadable to it (and agenix can't chown to a
      # user that doesn't exist yet); LoadCredential hands the file across.
      systemd.services.lldap.serviceConfig.LoadCredential = [
        "admin-password:${config.age.secrets.lldap-admin-password.path}"
      ];

      # lldap is a DynamicUser, so it has no static group membership; the ACME
      # certs are owned by acme:lldap-certs (group-readable), so add the group
      # via SupplementaryGroups for the LDAPS key/cert to be readable.
      systemd.services.lldap.serviceConfig.SupplementaryGroups = [ "lldap-certs" ];

      # LAN bridge only; the default sqlite DB lives in /var/lib/lldap.
      networking.firewall.interfaces.br0.allowedTCPPorts = [
        3890
        6360
        17170
      ];
    };
}
