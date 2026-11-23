{ config, ... }:
let
  topology = config.flake.meta.topology;
  # etcd/control-plane servers, each with its own scheduled window (auto-upgrade.nix).
  serverNames = [
    "io"
    "ceres"
    "callisto"
  ];
in
{
  # Homelab management tiers for the persistent albedo VM (owner-approved 2026-11-22).
  #
  # Tier 1, observe: an unprivileged `albedo` account. Not in wheel/docker/libvirt and not
  # a Nix allowed-user. It is in systemd-journal, which reads EVERY unit's logs; apps
  # sometimes log secrets, an accepted cost of the observe tier.
  #
  # Tier 3, deploy what is already merged: one exact sudo rule for `albedo-deploy-main`,
  # which only starts nixos-upgrade.service. That unit builds the fixed
  # `system.autoUpgrade.flake` (dotfiles main), so the agent can trigger but never choose
  # what gets deployed; root stays with whoever can merge main.
  #
  # On k3s servers every nixos-upgrade run, scheduled or triggered, takes the cluster-wide
  # Lease kube-system/nixos-upgrade first, so two etcd members never switch together.
  flake.modules.nixos.albedo-ops =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isServer = (config.services.k3s.enable or false) && config.services.k3s.role == "server";
      kubeconfig = "/etc/rancher/k3s/k3s.yaml";
      kubectl = "${pkgs.kubectl}/bin/kubectl --kubeconfig ${kubeconfig}";
      tools = lib.makeBinPath [
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.jq
        pkgs.systemd
      ];
      leaseSeconds = 2700; # 45 min, longer than any switch

      # acquire: create the Lease, or take it over only when it is ours or expired.
      # release: delete it only while this host holds it.
      lease = pkgs.writeShellScript "nixos-upgrade-lease" ''
        set -euo pipefail
        PATH=${tools}
        host=$(cat /proc/sys/kernel/hostname)
        manifest() {
          printf '{"apiVersion":"coordination.k8s.io/v1","kind":"Lease","metadata":{"name":"nixos-upgrade","namespace":"kube-system"%s},"spec":{"holderIdentity":"%s","leaseDurationSeconds":${toString leaseSeconds},"acquireTime":"%s","renewTime":"%s"}}' \
            "$1" "$host" "$2" "$2"
        }
        now=$(date -u +%Y-%m-%dT%H:%M:%S.000000Z)
        case "''${1:-}" in
          acquire)
            if current=$(${kubectl} -n kube-system get lease nixos-upgrade -o json 2>/dev/null); then
              holder=$(jq -r '.spec.holderIdentity // ""' <<<"$current")
              renew=$(jq -r '.spec.renewTime // ""' <<<"$current")
              duration=$(jq -r '.spec.leaseDurationSeconds // 0' <<<"$current")
              version=$(jq -r '.metadata.resourceVersion' <<<"$current")
              expires=$(( $(date -u -d "$renew" +%s 2>/dev/null || echo 0) + duration ))
              if [ "$holder" != "$host" ] && [ "$(date -u +%s)" -lt "$expires" ]; then
                echo "nixos-upgrade lease held by $holder until $(date -u -d @"$expires")" >&2
                exit 1
              fi
              # resourceVersion makes the takeover fail if someone else changed it meanwhile.
              manifest ",\"resourceVersion\":\"$version\"" "$now" | ${kubectl} replace -f - >/dev/null
            else
              manifest "" "$now" | ${kubectl} create -f - >/dev/null
            fi
            echo "nixos-upgrade lease acquired by $host"
            ;;
          release)
            # The switch may have just restarted k3s: retry for ~3 minutes. Never fail the
            # unit here; an unreleased lease expires on its own (45 min, inside the gaps
            # between the 04:00 / 05:00 / 06:30 server windows).
            for _ in $(seq 18); do
              if holder=$(${kubectl} -n kube-system get lease nixos-upgrade \
                   -o jsonpath='{.spec.holderIdentity}' 2>/dev/null); then
                if [ "$holder" = "$host" ]; then
                  ${kubectl} -n kube-system delete lease nixos-upgrade --ignore-not-found >/dev/null || true
                fi
                exit 0
              fi
              sleep 10
            done
            echo "could not reach the API to release the nixos-upgrade lease; it expires on its own" >&2
            exit 0
            ;;
          *)
            echo "usage: nixos-upgrade-lease acquire|release" >&2
            exit 2
            ;;
        esac
      '';

      deploy = pkgs.writeShellScriptBin "albedo-deploy-main" ''
        set -euo pipefail
        PATH=${tools}
        host=$(cat /proc/sys/kernel/hostname)
        if [ "$#" -ne 0 ]; then
          echo "albedo-deploy-main takes no arguments" >&2
          exit 2
        fi
        if systemctl is-active --quiet nixos-upgrade.service; then
          echo "nixos-upgrade is already running on $host" >&2
          exit 1
        fi
        ${lib.optionalString isServer ''
          hour=$(date +%H)
          if [ "$hour" -ge 4 ] && [ "$hour" -lt 7 ]; then
            echo "refusing during the scheduled etcd-server windows (04:00-07:00)" >&2
            exit 1
          fi
          # Quorum health: every control-plane node Ready and every server's /readyz ok.
          notready=$(${kubectl} get nodes -l node-role.kubernetes.io/control-plane \
            --no-headers | awk '$2 != "Ready" {print $1}')
          if [ -n "$notready" ]; then
            echo "refusing: control-plane node(s) not Ready: $notready" >&2
            exit 1
          fi
          ${lib.concatMapStrings (name: ''
            if ! ${kubectl} --server https://${topology.hosts.${name}.lanAddress}:6443 \
                 get --raw /readyz >/dev/null 2>&1; then
              echo "refusing: ${name} /readyz is not ok" >&2
              exit 1
            fi
          '') serverNames}
          # The unit itself takes the Lease; checking here gives a clear message early.
          if holder=$(${kubectl} -n kube-system get lease nixos-upgrade \
               -o jsonpath='{.spec.holderIdentity}' 2>/dev/null) && [ -n "$holder" ] && [ "$holder" != "$host" ]; then
            echo "refusing: nixos-upgrade lease is held by $holder" >&2
            exit 1
          fi
        ''}
        echo "starting nixos-upgrade.service on $host (builds ${config.system.autoUpgrade.flake})"
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

      # Scheduled and triggered upgrades alike take the cluster Lease on servers. If the API
      # is unreachable the run fails (and alerts) rather than risk two etcd members at once;
      # a human can still switch by hand.
      systemd.services.nixos-upgrade.serviceConfig = lib.mkIf isServer {
        ExecStartPre = [ "${lease} acquire" ];
        ExecStopPost = [ "${lease} release" ];
      };

      assertions = [
        {
          assertion = !(lib.elem "wheel" config.users.users.albedo.extraGroups);
          message = "the albedo account must never be in wheel (Nix trusted-users is root-equivalent)";
        }
      ];
    };
}
