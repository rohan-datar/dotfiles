_: {
  # Offsite copy of the k3s control plane's recovery material. k3s itself writes an
  # embedded-etcd snapshot every 12 h (00:00/12:00, 5 kept) to the directory below; this
  # ships those plus the server token, which a snapshot restore requires (k3s
  # `--cluster-reset --cluster-reset-restore-path`). Same Storage Box and password as
  # the other restic repos; own repository path. The sops-age key is inside the
  # snapshots (a Secret) and is also break-glass-encrypted in oort-cloud.
  flake.modules.nixos.k3s-etcd-restic =
    { config, ... }:
    {
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      services.restic.backups.k3s-etcd = {
        repository = "sftp:u630851-sub1@u630851.your-storagebox.de:restic/io";
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [
          "sftp.command='ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp'"
        ];
        initialize = true;
        paths = [
          "/var/lib/rancher/k3s/server/db/snapshots"
          "/var/lib/rancher/k3s/server/token"
        ];
        # 30 minutes after each k3s snapshot.
        timerConfig = {
          OnCalendar = "*-*-* 00,12:30";
          Persistent = true;
          RandomizedDelaySec = "10m";
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
        runCheck = true;
        checkOpts = [ "--read-data-subset=5%" ];
      };

      systemd.services."restic-backups-k3s-etcd".unitConfig.OnFailure = [
        "backup-failure-email@%n.service"
      ];
    };
}
