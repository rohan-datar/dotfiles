_: {
  # Backups of the k3s durable tier (ADR 0014 step 6). The app volumes are ZFS zvols with
  # ext4 inside (democratic-csi, data-pool/k8s/iscsi), so file-level restic can't see their
  # contents. Each job, on its own:
  #   1. snapshots every zvol, clones the snapshot under data-pool/k8s/backup-clones,
  #   2. mounts each clone read-only at /run/<job>/<namespace>/<pvc> (stable paths, so restic
  #      deduplicates run to run; the clone is writable so ext4 can replay its journal),
  #   3. runs restic over that tree, then unmounts and destroys clones + snapshots (also on
  #      failure: backupCleanupCommand is ExecStopPost).
  # Two independent copies (3-2-1 with the live pool): the Storage Box (off-site) and a
  # repository on ganymede's Btrfs RAID1 (on-site, LAN-speed restores).
  # Consistency: crash-consistent snapshots (SQLite WAL recovers like after power loss).
  # Per-app pre-snapshot hooks are a follow-up (ADR 0014).
  flake.modules.nixos.nas-k8s-volume-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      zfs = "${config.boot.zfs.package}/bin/zfs";
      clones = "data-pool/k8s/backup-clones";
      keyDir = "/mnt/data-pool/k8s/backup-keys"; # on the pool: moves with a chassis swap
      prepare = job: ''
        set -euo pipefail
        ${cleanup job}
        stamp="${job}-$(date +%Y%m%d%H%M%S)"
        install -d -m 0700 /run/${job}
        for zv in $(${zfs} list -H -o name -t volume -r data-pool/k8s/iscsi); do
          pvc=$(${zfs} get -H -o value org.rdatar:pvc "$zv")
          [ "$pvc" = "-" ] && pvc="unlabelled/$(basename "$zv")"
          ${zfs} snapshot "$zv@$stamp"
          clone="${clones}/${job}-$(basename "$zv")"
          ${zfs} clone "$zv@$stamp" "$clone"
          for _ in $(seq 1 30); do [ -e "/dev/zvol/$clone" ] && break; sleep 1; done
          mkdir -p "/run/${job}/$pvc"
          ${pkgs.util-linux}/bin/mount -o ro "/dev/zvol/$clone" "/run/${job}/$pvc"
        done
      '';
      cleanup = job: ''
        for m in $(${pkgs.util-linux}/bin/findmnt -rn -o TARGET | grep '^/run/${job}/' | sort -r); do
          ${pkgs.util-linux}/bin/umount "$m" || ${pkgs.util-linux}/bin/umount -l "$m"
        done
        rm -rf /run/${job}
        for c in $(${zfs} list -H -o name -t volume -r ${clones} | grep "^${clones}/${job}-" || true); do
          ${zfs} destroy "$c"
        done
        for s in $(${zfs} list -H -o name -t snapshot -r data-pool/k8s/iscsi | grep "@${job}-" || true); do
          ${zfs} destroy "$s"
        done
      '';
      job = name: repository: sftpCommand: timer: keep: {
        inherit repository;
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [ "sftp.command='${sftpCommand}'" ];
        initialize = true;
        paths = [ "/run/${name}" ];
        backupPrepareCommand = prepare name;
        backupCleanupCommand = cleanup name;
        timerConfig = {
          OnCalendar = timer;
          Persistent = true;
          RandomizedDelaySec = "10m";
        };
        pruneOpts = keep;
        runCheck = true;
        checkOpts = [ "--read-data-subset=5%" ];
      };
    in
    {
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      services.restic.backups = {
        k8s-volumes-ganymede =
          job "k8s-volumes-ganymede" "sftp:restic-nas@10.10.1.15:/srv/restic-nas/ceres-k8s"
            "ssh -i ${keyDir}/id_ed25519 -o StrictHostKeyChecking=accept-new restic-nas@10.10.1.15 -s sftp"
            "01:00"
            [
              "--keep-daily 14"
              "--keep-weekly 8"
              "--keep-monthly 6"
            ];
        k8s-volumes-storagebox =
          job "k8s-volumes-storagebox" "sftp:u630851-sub1@u630851.your-storagebox.de:restic/ceres-k8s"
            "ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp"
            "01:45"
            [
              "--keep-daily 7"
              "--keep-weekly 5"
              "--keep-monthly 12"
            ];
      };

      # Jobs use their own snapshot/clone name prefix, so they can't disturb each other.
      systemd.services =
        lib.genAttrs [ "restic-backups-k8s-volumes-ganymede" "restic-backups-k8s-volumes-storagebox" ] (_: {
          unitConfig.OnFailure = [ "backup-failure-email@%n.service" ];
          # Each Exec* step gets its own private mount namespace with PrivateTmp, so the
          # clones mounted in the prepare step would be invisible to restic. Mount in the
          # host namespace instead (/run/<job> is 0700 root).
          serviceConfig.PrivateTmp = lib.mkForce false;
        })
        // {
          k8s-storage-datasets.postStart = ''
            ${zfs} list -H ${clones} >/dev/null 2>&1 || ${zfs} create ${clones}
          '';
        };
    };
}
