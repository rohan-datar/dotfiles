_: {
  flake.modules.nixos.lldap =
    { config, ... }:
    {
      # JWT signing secret + private-key seed. The admin password lives in its
      # own file because the nixpkgs module's assertion only accepts a *path*
      # (`LLDAP_LDAP_USER_PASS_FILE`) — it cannot see inside an EnvironmentFile.
      age.secrets.lldap-env.file = ../../../secrets/lldap-env.age;
      age.secrets.lldap-admin-password.file = ../../../secrets/lldap-admin-password.age;

      services.lldap = {
        enable = true;
        environmentFile = config.age.secrets.lldap-env.path;
        # %d = the systemd credentials dir; see LoadCredential below.
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

      # LAN bridge only; the default sqlite DB lives in /var/lib/lldap.
      networking.firewall.interfaces.br0.allowedTCPPorts = [
        3890
        17170
      ];
    };
}
