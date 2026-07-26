_: {
  flake.modules.nixos.nas-paperless =
    { config, ... }:
    {
      age.secrets.paperless-admin-password.file = ../../../secrets/paperless-admin-password.age;
      age.secrets.paperless-oidc-env.file = ../../../secrets/paperless-oidc-env.age;

      services.paperless = {
        enable = true;
        dataDir = "/mnt/data-pool/paperless";
        # Drop scans into the SMB share from any machine; paperless consumes and files them.
        consumptionDir = "/mnt/data-pool/data-share/paperless-inbox";
        consumptionDirIsPublic = true;
        address = "0.0.0.0";
        port = 28981;
        passwordFile = config.age.secrets.paperless-admin-password.path;
        database.createLocally = true;
        environmentFile = config.age.secrets.paperless-oidc-env.path;
        exporter = {
          enable = true; # nightly document_exporter → the restic path
          directory = "/mnt/data-pool/paperless-export";
        };
        settings = {
          PAPERLESS_URL = "https://docs.datars.org";
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS = "false";
        };
      };

      networking.firewall.interfaces.enp2s0.allowedTCPPorts = [ 28981 ];
    };
}
