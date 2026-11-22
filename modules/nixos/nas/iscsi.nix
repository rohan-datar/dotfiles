{ config, ... }:
let
  topology = config.flake.meta.topology;
in
{
  # iSCSI target for the k3s durable storage tier (ADR 0014). democratic-csi
  # (zfs-generic-iscsi, in oort-cloud) logs in over SSH as `democratic-csi` and, per PVC:
  # creates a zvol under data-pool/k8s/iscsi and publishes it through LIO with targetcli.
  #
  # - The published-volume table is runtime state written by targetcli, not Nix config: it
  #   lives on the pool (data-pool/k8s/target, symlinked as /etc/target) so it survives
  #   reboots and moves with the pool. nixpkgs' services.target is deliberately NOT used:
  #   it regenerates /etc/target/saveconfig.json from Nix on every switch, which would drop
  #   democratic-csi's LUNs.
  # - ZFS rights are delegated (`zfs allow`) on the two k8s datasets only — no sudo for zfs,
  #   so the CSI key cannot touch data-share, paperless, etc. sudo is limited to targetcli.
  #   (targetcli itself can publish any block device: protect the private key, which is a
  #   SOPS secret in oort-cloud.)
  # - Portal 3260 open only to the k3s node IPs; CHAP is configured by democratic-csi.
  flake.modules.nixos.nas-iscsi =
    { pkgs, ... }:
    let
      csiUser = "democratic-csi";
      parent = "data-pool/k8s";
      targetDir = "/mnt/data-pool/k8s/target";
      targetctl = "${pkgs.python3Packages.rtslib-fb}/bin/targetctl";
      zfs = "${config.boot.zfs.package or pkgs.zfs}/bin/zfs";
      delegated = "create,destroy,snapshot,clone,promote,rename,mount,hold,release,send,receive,userprop,volsize,volblocksize,volmode,compression,refreservation,reservation,dedup,checksum";
    in
    {
      boot.kernelModules = [
        "configfs"
        "target_core_mod"
        "iscsi_target_mod"
      ];
      environment.systemPackages = [ pkgs.targetcli-fb ];

      users.groups.${csiUser} = { };
      users.users.${csiUser} = {
        isSystemUser = true;
        group = csiUser;
        # democratic-csi runs `sh -c 'echo … | sudo targetcli'` and plain `zfs …`.
        shell = pkgs.bash;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBxehx5VXPl/ScLwXpH4cLyxhCt2Dzna9LoQyx+JYcUy democratic-csi@k3s"
        ];
      };
      security.sudo.extraRules = [
        {
          users = [ csiUser ];
          commands = [
            {
              command = "/run/current-system/sw/bin/targetcli";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      # Datasets + delegation, idempotent on every boot/switch.
      systemd.services.k8s-storage-datasets = {
        description = "ZFS datasets and delegation for k3s durable storage";
        after = [ "zfs-mount.service" ];
        requires = [ "zfs-mount.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          for ds in ${parent} ${parent}/iscsi ${parent}/iscsi-snapshots ${parent}/target; do
            ${zfs} list -H "$ds" >/dev/null 2>&1 || ${zfs} create "$ds"
          done
          ${zfs} allow -u ${csiUser} ${delegated} ${parent}/iscsi
          ${zfs} allow -u ${csiUser} ${delegated} ${parent}/iscsi-snapshots
          chmod 0700 ${targetDir}
        '';
      };

      # LIO state lives on the pool; /etc/target points at it.
      systemd.tmpfiles.rules = [ "L+ /etc/target - - - - ${targetDir}" ];

      systemd.services.iscsi-target-restore = {
        description = "Restore the LIO iSCSI target from the on-pool saveconfig";
        after = [
          "k8s-storage-datasets.service"
          "sys-kernel-config.mount"
          "network.target"
        ];
        requires = [ "k8s-storage-datasets.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathExists = "${targetDir}/saveconfig.json";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${targetctl} restore ${targetDir}/saveconfig.json";
          # Persist the current state on shutdown too (targetcli also saves after each change).
          ExecStop = "${targetctl} save ${targetDir}/saveconfig.json";
        };
      };

      networking.firewall.extraCommands = builtins.concatStringsSep "" (
        map
          (ip: ''
            iptables -A nixos-fw -p tcp --dport 3260 -s ${ip} -j nixos-fw-accept
          '')
          [
            topology.hosts.io.lanAddress
            topology.hosts.ganymede.lanAddress
            topology.hosts.europa.lanAddress
            topology.hosts.callisto.lanAddress
          ]
      );
    };
}
