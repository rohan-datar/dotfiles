_: {
  # Offsite backup of native media application state on europa (/data/.state/nixarr).
  # Live SQLite databases (*arr, Seerr, Komga, Jellyfin, Bazarr, Qui, Shelfmark) use WAL
  # mode and must never be copied raw while running: backupPrepareCommand snapshots every
  # SQLite file under /data/.state/nixarr (skipping cache/log/MediaCover/transcode trees)
  # via `sqlite3 .backup` into /var/backup/nixarr-sqlite preserving relative paths, while
  # restic backs up /var/backup/nixarr-sqlite plus non-SQLite config/secrets/BT_backup from
  # /data/.state/nixarr. Once services migrate onto ADR 0014 iSCSI volumes, this job
  # automatically shrinks to whatever native state remains on europa.
  flake.modules.nixos.europa-restic =
    { config, pkgs, ... }:
    let
      stateRoot = "/data/.state/nixarr";
      sqliteStage = "/var/backup/nixarr-sqlite";
    in
    {
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      services.restic.backups.media = {
        repository = "sftp:u630851-sub1@u630851.your-storagebox.de:restic/europa";
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [
          "sftp.command='ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp'"
        ];
        initialize = true;

        backupPrepareCommand = ''
          set -euo pipefail
          rm -rf ${sqliteStage}
          mkdir -p -m 0700 ${sqliteStage}
          if [ -d ${stateRoot} ]; then
            ${pkgs.findutils}/bin/find ${stateRoot} \
              \( \
                -path "${stateRoot}/jellyfin/cache" -o \
                -path "${stateRoot}/jellyfin/log" -o \
                -path "${stateRoot}/jellyfin/data/transcodes" -o \
                -path "${stateRoot}/jellyfin/data/metadata" -o \
                -path "${stateRoot}/jellyfin/data/keyframes" -o \
                -path "${stateRoot}/jellyfin/data/trickplay" -o \
                -path "${stateRoot}/*/MediaCover" -o \
                -path "${stateRoot}/*/logs" -o \
                -path "${stateRoot}/*/log" -o \
                -path "${stateRoot}/*/Backups" \
              \) -prune -o \
              -type f \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) -print0 \
            | while IFS= read -r -d ''' db; do
                rel="''${db#${stateRoot}/}"
                dest="${sqliteStage}/''${rel}"
                mkdir -p -m 0700 "$(dirname "$dest")"
                # timeout 30000 ms avoids failing if an *arr task briefly holds a write lock.
                ${pkgs.sqlite}/bin/sqlite3 "$db" ".timeout 30000" ".backup '$dest'"
              done
          fi
        '';

        backupCleanupCommand = ''
          rm -rf ${sqliteStage}
        '';

        paths = [
          sqliteStage
          stateRoot
        ];

        exclude = [
          # Anchor SQLite excludes to stateRoot so staged copies under sqliteStage are KEPT.
          "${stateRoot}/**/*.db"
          "${stateRoot}/**/*.db-wal"
          "${stateRoot}/**/*.db-shm"
          "${stateRoot}/**/*.db-journal"
          "${stateRoot}/**/*.sqlite"
          "${stateRoot}/**/*.sqlite-wal"
          "${stateRoot}/**/*.sqlite-shm"
          "${stateRoot}/**/*.sqlite-journal"
          "${stateRoot}/**/*.sqlite3"
          "${stateRoot}/**/*.sqlite3-wal"
          "${stateRoot}/**/*.sqlite3-shm"
          "${stateRoot}/**/*.sqlite3-journal"
          # Rebuildable artwork, metadata, logs, caches, and duplicate automatic DB zips.
          "${stateRoot}/jellyfin/cache"
          "${stateRoot}/jellyfin/log"
          "${stateRoot}/jellyfin/data/transcodes"
          "${stateRoot}/jellyfin/data/metadata"
          "${stateRoot}/jellyfin/data/keyframes"
          "${stateRoot}/jellyfin/data/trickplay"
          "${stateRoot}/*/MediaCover"
          "${stateRoot}/*/logs"
          "${stateRoot}/*/log"
          "${stateRoot}/*/Backups"
          "${stateRoot}/qbittorrent/qBittorrent/data/logs"
          "${stateRoot}/recyclarr/cache"
          "${stateRoot}/recyclarr/logs"
          "${stateRoot}/recyclarr/repositories"
        ];

        # Run before europa's 03:30 unattended upgrade window so pre-upgrade state is captured.
        timerConfig = {
          OnCalendar = "02:45";
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
