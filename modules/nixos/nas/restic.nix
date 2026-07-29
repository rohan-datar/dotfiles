_: {
  # Offsite documents backup: nightly paperless export + the general SMB share,
  # minus media and books (RAIDZ1 + sanoid cover those; treated as re-obtainable).
  # Repo-per-host on the Hetzner Storage Box over SFTP:23 with a dedicated
  # keypair — separate locking and blast radius from home-controller's repo.
  # Failure path: Persistent=true replays missed runs, OnFailure mails via the
  # shared `mail` aspect's backup-failure-email@ template.
  flake.modules.nixos.nas-restic =
    { config, ... }:
    {
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      services.restic.backups.data = {
        repository = "sftp:u630851-sub1@u630851.your-storagebox.de:restic/home-nas";
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [
          "sftp.command='ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp'"
        ];
        initialize = true; # first run does restic init
        paths = [
          "/mnt/data-pool/paperless-export"
          "/mnt/data-pool/data-share"
        ];
        exclude = [
          "/mnt/data-pool/data-share/media" # media AND books (media/library/books)
          "/mnt/data-pool/data-share/paperless-inbox" # transient; consumed into paperless anyway
        ];
        # 03:30 keeps the backup at least an hour behind the nightly paperless
        # export so each run carries that night's documents. Verify the export
        # timer's OnCalendar on the live host: `systemctl cat paperless-exporter.timer`.
        timerConfig = {
          OnCalendar = "03:30";
          Persistent = true; # missed runs (host was off) fire on boot
          RandomizedDelaySec = "15m";
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];
        runCheck = true;
        checkOpts = [ "--read-data-subset=2%" ]; # cheap continuous verification of repo integrity
      };

      systemd.services."restic-backups-data".unitConfig.OnFailure = [
        "backup-failure-email@%n.service"
      ];
    };
}
