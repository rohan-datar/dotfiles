_: {
  # Disk-health *metrics*, for graphing. The alerts for the same conditions
  # already email directly from smartd/ZED (nas-alerts) — this aspect adds no
  # alerting of its own, which is why it is separate from nas-alerts.
  flake.modules.nixos.nas-metrics = _: {
    # Pool/dataset/vdev state and IO. Reads via `zpool`, so it needs the host's
    # ZFS package — the nixpkgs module wires that up for us.
    services.prometheus.exporters.zfs.enable = true; # :9134

    # Per-drive SMART attributes. Autodiscovers devices when `devices` is empty
    # and the module grants itself the capabilities/device access it needs.
    services.prometheus.exporters.smartctl.enable = true; # :9633
  };
}
