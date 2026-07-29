_: {
  # WAN throughput graphs, replacing the old TrueNAS speedtest app. Lives on the
  # controller so the monitoring stack stays on one host; Prometheus is local, so
  # the exporter binds loopback and opens no firewall port.
  #
  # The exporter keeps no cache and has no schedule of its own: it runs a full
  # speedtest inline on every scrape (~40s, one at a time) and saturates the WAN
  # while it does. The cadence is therefore purely a property of the scrape job,
  # which is why it ships with the exporter here instead of living in the
  # prometheus aspect — dropping this import removes both halves at once.
  flake.modules.nixos.speedtest = _: {
    services.prometheus.exporters.speedtest = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9798;
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "speedtest";
        # Overrides the 30s global. Hourly matches upstream's own recommendation:
        # one 40s WAN-saturating test per hour is ~1% duty cycle on a link the
        # family also streams over, and it halves the churn from the per-test
        # `test_uuid` label (every run mints a fresh series).
        scrape_interval = "60m";
        # Must outlast the test; the exporter's own handler gives up at 60s.
        scrape_timeout = "60s";
        static_configs = [ { targets = [ "127.0.0.1:9798" ]; } ];
      }
    ];
  };
}
