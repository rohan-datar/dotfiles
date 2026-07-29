_: {
  # Host-level metrics for every NixOS server; Prometheus on home-controller
  # scrapes :9100. No firewall opinion here — the LAN interface differs per host,
  # so each host file opens the port next to its own networking block (the
  # controller scrapes itself over loopback and opens nothing).
  flake.modules.nixos.metrics-agent = _: {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [ "systemd" ];
    };
  };
}
