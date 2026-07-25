_: {
  flake.modules.nixos.keycloak =
    { config, ... }:
    {
      age.secrets.keycloak-db-password.file = ../../../secrets/keycloak-db-password.age;

      services.keycloak = {
        enable = true;
        database = {
          type = "postgresql";
          createLocally = true;
          passwordFile = config.age.secrets.keycloak-db-password.path;
        };

        initialAdminPassword = "admin";

        settings = {
          hostname = "auth.datars.org";
          http-enabled = true;
          http-host = "0.0.0.0";
          http-port = 8080;
          proxy-headers = "xforwarded";
        };
      };

      networking.firewall.interfaces.br0.allowedTCPPorts = [ 8080 ];
    };
}
