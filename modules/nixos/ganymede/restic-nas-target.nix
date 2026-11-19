_: {
  # On-site copy of the k3s durable tier (ADR 0014): home-nas writes a restic repository
  # here over SFTP, on ganymede's Btrfs RAID1 (separate disks from the NAS pool).
  # The key may only run the SFTP server; the user owns nothing but its repository dir.
  flake.modules.nixos.restic-nas-target =
    { pkgs, ... }:
    {
      users.groups.restic-nas = { };
      users.users.restic-nas = {
        isSystemUser = true;
        group = "restic-nas";
        home = "/srv/restic-nas";
        createHome = true;
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = [
          ''restrict,command="${pkgs.openssh}/libexec/sftp-server" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJlCBTd67mged4MQhYBhRxyjVtw9l8uQ8dvslOHDiH/V home-nas-k8s-backup''
        ];
      };
      # The data lives on the Btrfs RAID1, whose root (k3s local-path storage) is 0700 root;
      # bind it to its own path so restic-nas can reach it without opening that root up.
      systemd.tmpfiles.rules = [
        "d /var/lib/rancher/k3s/storage/restic 0700 restic-nas restic-nas -"
        "d /srv/restic-nas 0700 restic-nas restic-nas -"
      ];
      fileSystems."/srv/restic-nas" = {
        device = "/var/lib/rancher/k3s/storage/restic";
        fsType = "none";
        options = [
          "bind"
          "x-systemd.requires-mounts-for=/var/lib/rancher/k3s/storage"
        ];
      };
    };
}
