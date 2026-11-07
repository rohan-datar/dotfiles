_:
let
  # local-path-retain PVC for onedev/onedev-0 (StatefulSet data-onedev-0),
  # mounted at /opt/onedev in the pod. The path changes only if the PVC is
  # recreated; then update it here.
  onedevData = "/var/lib/rancher/k3s/storage/pvc-c38b8240-051b-405a-93ce-0b7f55fe965e_onedev_data-onedev-0";
in
{
  # Offsite OneDev backup (git.rdatar.com). The live HSQLDB under internaldb/ is
  # never copied: OneDev's own scheduled database backup (Administration ->
  # Database Backup, 08:00 UTC) writes consistent zips to db-backup/, and this
  # job ships those plus site/ (git repositories, attachments, build data).
  # site/index is a rebuildable Lucene index. Same Storage Box, own repo.
  flake.modules.nixos.onedev-restic =
    { config, ... }:
    {
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      services.restic.backups.onedev = {
        repository = "sftp:u630851-sub1@u630851.your-storagebox.de:restic/ganymede";
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [
          "sftp.command='ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp'"
        ];
        initialize = true;
        paths = [
          "${onedevData}/db-backup"
          "${onedevData}/site"
          "${onedevData}/conf"
        ];
        exclude = [ "${onedevData}/site/index" ];
        # At least 90 minutes after OneDev's 08:00 UTC (02:00 CST) database backup.
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
        runCheck = true;
        checkOpts = [ "--read-data-subset=2%" ];
      };

      systemd.services."restic-backups-onedev".unitConfig = {
        OnFailure = [ "backup-failure-email@%n.service" ];
        # Never back up the empty directory local-path leaves when the RAID1 is not
        # mounted; fail (and mail) instead.
        RequiresMountsFor = [ onedevData ];
      };
    };
}
