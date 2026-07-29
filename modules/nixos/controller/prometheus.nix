_: {
  # Metrics store for the lab. Grafana and Gatus are the only consumers and both
  # live on this host, so Prometheus binds loopback only and opens no port.
  #
  # Port 9091, not the usual 9090: cockpit (ha-vm aspect) already owns 9090 on
  # every interface here, so 9090 would fail to bind.
  #
  # No Alertmanager on purpose — smartd/ZED email hardware faults directly and
  # Gatus owns availability alerting. Alertmanager stays an additive change.
  flake.modules.nixos.prometheus = { config, ... }: {
    age.secrets.ha-prometheus-token = {
      file = ../../../secrets/ha-prometheus-token.age;
      owner = "prometheus";
    };

    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9091;
      retentionTime = "90d";
      globalConfig.scrape_interval = "30s";

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "localhost:9100" # home-controller
                "10.10.1.11:9100" # home-media
                "10.10.1.10:9100" # home-nas
                "10.10.0.1:9100" # OPNsense — uncomment once os-node_exporter is installed
              ];
            }
          ];
        }
        {
          job_name = "zfs";
          static_configs = [ { targets = [ "10.10.1.10:9134" ]; } ];
        }
        {
          job_name = "smartctl";
          static_configs = [ { targets = [ "10.10.1.10:9633" ]; } ];
        }
        {
          job_name = "gatus";
          static_configs = [ { targets = [ "localhost:8081" ]; } ];
        }
        # Home Assistant, once the `prometheus:` integration and its long-lived
        # token exist (ha-prometheus-token.age, owner = "prometheus"):
        {
          job_name = "homeassistant";
          metrics_path = "/api/prometheus";
          bearer_token_file = config.age.secrets.ha-prometheus-token.path;
          static_configs = [ { targets = [ "10.10.1.12:8123" ]; } ];
        }
      ];
    };
  };
}
