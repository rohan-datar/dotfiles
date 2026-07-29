_: {
  # Offsite identity backup: losing this host's state loses every account and
  # passkey in the lab. PostgreSQL (Keycloak) via the in-tree dump service —
  # consistent dumps on their own timer, an hour before restic picks them up;
  # lldap via a prepare-command SQLite .backup (safe hot copy; the DB is tiny
  # and rarely written). Same Storage Box as home-nas but its own repo:
  # separate locking, separate blast radius.
  flake.modules.nixos.controller-restic =
    { config, pkgs, ... }:
    {
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      # Nightly pg_dump → /var/backup/postgresql/keycloak.sql.gz
      services.postgresqlBackup = {
        enable = true;
        databases = [ "keycloak" ];
        startAt = "*-*-* 02:30:00";
      };

      services.restic.backups.identity = {
        repository = "sftp:u630851-sub1@u630851.your-storagebox.de:restic/home-controller";
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [
          "sftp.command='ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp'"
        ];
        initialize = true;
        # lldap is DynamicUser: real state is /var/lib/private/lldap with a
        # symlink at /var/lib/lldap; restic runs as root so both paths work.
        # Verify the filename on the live host (`sudo ls /var/lib/lldap`).
        backupPrepareCommand = ''
          mkdir -p /var/backup/lldap
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/lldap/users.db ".backup /var/backup/lldap/users.db"
        '';
        paths = [
          "/var/backup/postgresql"
          "/var/backup/lldap"
        ];
        timerConfig = {
          OnCalendar = "03:30";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];
        # Not in the guide's 4.3 block, but the repo is a few MB and this data
        # is the most precious in the lab — the 2% read-back costs nothing here.
        runCheck = true;
        checkOpts = [ "--read-data-subset=2%" ];
      };

      systemd.services."restic-backups-identity".unitConfig.OnFailure = [
        "backup-failure-email@%n.service"
      ];
      systemd.services."postgresqlBackup-keycloak".unitConfig.OnFailure = [
        "backup-failure-email@%n.service"
      ];
    };
}
