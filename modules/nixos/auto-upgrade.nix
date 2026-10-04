# Unattended upgrades for always-on NixOS servers.
_: {
  flake.modules.nixos.auto-upgrade =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      age.secrets.upgrade-ntfy-env.file = ../../secrets/upgrade-ntfy-env.age;

      system.autoUpgrade = {
        enable = lib.mkDefault true;

        flake = lib.mkDefault "github:rohan-datar/dotfiles";

        dates = lib.mkDefault "*-*-* 05:00";
        randomizedDelaySec = lib.mkDefault "45min";

        allowReboot = lib.mkDefault false; # reboots stay a deliberate act
        persistent = lib.mkDefault true; # catch up if the machine was off
      };

      systemd.services.nixos-upgrade = {
        onFailure = [ "ntfy-failure@%n.service" ];
        # Bound the upgrade service, including its evaluator and activation.
        # A failed upgrade is preferable to starving HAOS and running services.
        # Inspect activation after an OOM failure rather than blindly retrying.
        # Builds owned by nix-daemon in a separate cgroup are not covered.
        serviceConfig = {
          MemoryHigh = lib.mkDefault "3G";
          MemoryMax = lib.mkDefault "4G";
          OOMScoreAdjust = lib.mkDefault 500;
          OOMPolicy = "kill";
          MemoryOOMGroup = true;
        };
      };

      systemd.units."ntfy-failure@.service".text = ''
        [Unit]
        Description=Push an ntfy alert after %i fails

        [Service]
        Type=oneshot
        EnvironmentFile=${config.age.secrets.upgrade-ntfy-env.path}
        # %I = unescaped instance name (e.g. nixos-upgrade.service),
        # %H = this host. Posts to the same "homelab" topic Gatus uses,
        # so the phone needs no extra subscription.
        ExecStart=${pkgs.curl}/bin/curl -fsS --max-time 30 \
          -H "Authorization: Bearer ''${UPGRADE_NTFY_TOKEN}" \
          -H "Title: %I failed on %H" \
          -H "Tags: rotating_light" \
          -d "%I failed on %H — inspect: ssh %H journalctl -u %I" \
          https://ntfy.datars.org/homelab
      '';
    };
}
