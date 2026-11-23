_: {
  # Homelab management tiers for the persistent albedo VM (owner-approved 2026-11-22).
  # Tier 1, observe: an unprivileged `albedo` account (journal read, no wheel/docker/libvirt,
  # not a Nix allowed-user). Tier 3, deploy what is already merged: one exact sudo rule for
  # `albedo-deploy-main`, which only starts nixos-upgrade.service. That unit builds the fixed
  # `system.autoUpgrade.flake` (dotfiles main), so the agent can trigger but never choose
  # what gets deployed; root stays with whoever can merge main.
  flake.modules.nixos.albedo-ops =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isServer = (config.services.k3s.enable or false) && config.services.k3s.role == "server";
      kubectl = "${pkgs.kubectl}/bin/kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml";
      deploy = pkgs.writeShellScriptBin "albedo-deploy-main" ''
        set -euo pipefail
        PATH=${
          lib.makeBinPath [
            pkgs.systemd
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gawk
          ]
        }
        if [ "$#" -ne 0 ]; then
          echo "albedo-deploy-main takes no arguments" >&2
          exit 2
        fi
        if systemctl is-active --quiet nixos-upgrade.service; then
          echo "nixos-upgrade is already running on $(cat /proc/sys/kernel/hostname)" >&2
          exit 1
        fi
        ${lib.optionalString isServer ''
          # etcd quorum: never switch while another control-plane node is not Ready (it may
          # be mid-upgrade), and stay out of the scheduled server windows (04:00-07:00).
          hour=$(date +%H)
          if [ "$hour" -ge 4 ] && [ "$hour" -lt 7 ]; then
            echo "refusing during the scheduled etcd-server upgrade windows (04:00-07:00)" >&2
            exit 1
          fi
          notready=$(${kubectl} get nodes -l node-role.kubernetes.io/control-plane \
            --no-headers | awk '$2 != "Ready" {print $1}')
          if [ -n "$notready" ]; then
            echo "refusing: control-plane node(s) not Ready: $notready" >&2
            exit 1
          fi
        ''}
        echo "starting nixos-upgrade.service on $(cat /proc/sys/kernel/hostname) (builds ${config.system.autoUpgrade.flake})"
        exec systemctl start --no-block nixos-upgrade.service
      '';
    in
    {
      users.groups.albedo = { };
      users.users.albedo = {
        isNormalUser = true;
        group = "albedo";
        description = "albedo agent (unprivileged)";
        extraGroups = [ "systemd-journal" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGX9r/aBfkor0VB1lO6OhbTGK/fkf2CA7YetE7pnRmvg albedo@pallas"
        ];
      };

      environment.systemPackages = [ deploy ];

      security.sudo.extraRules = [
        {
          users = [ "albedo" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/albedo-deploy-main";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      assertions = [
        {
          assertion = !(lib.elem "wheel" config.users.users.albedo.extraGroups);
          message = "the albedo account must never be in wheel (Nix trusted-users is root-equivalent)";
        }
      ];
    };
}
