_: {
  # Warpgate Backup
  flake.modules.nixos.media-restic =
    { config, pkgs, ... }:
    {
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      services.restic.backups.media = {
        repository = "sftp:u630851-sub1@u630851.your-storagebox.de:restic/home-media";
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [
          "sftp.command='ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp'"
        ];
        initialize = true;

        backupPrepareCommand = ''
          mkdir -p /var/backup/warpgate
          for db in /var/lib/private/warpgate/*.sqlite3; do
            [ -e "$db" ] || continue
            ${pkgs.sqlite}/bin/sqlite3 "$db" ".backup /var/backup/warpgate/$(basename "$db")"
          done
        '';

        paths = [
          "/var/backup/warpgate"
          "/var/lib/private/warpgate"
        ];

        exclude = [ "/var/lib/private/warpgate/*.sqlite3*" ];

        timerConfig = {
          OnCalendar = "03:45";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];

        runCheck = true;
        checkOpts = [ "--read-data-subset=2%" ];
      };

      systemd.services."restic-backups-media".unitConfig.OnFailure = [
        "backup-failure-email@%n.service"
      ];
    };
}
