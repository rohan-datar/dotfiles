_: {
  # WAN speedtest metrics
  flake.modules.nixos.speedtest =
    { pkgs, lib, ... }:
    let
      # node_exporter reads *.prom from here. The scratch file deliberately does not end in
      # .prom, so a half-written file is never parsed; the rename over it is atomic.
      textfileDir = "/var/lib/prometheus-node-exporter-text-files";

      speedtest-metrics = pkgs.writers.writePython3Bin "speedtest-metrics" {
      } (builtins.readFile ./speedtest-metrics.py);
    in
    {
      # Merges with the collector list set in modules/nixos/metrics-agent.nix.
      services.prometheus.exporters.node = {
        enabledCollectors = [ "textfile" ];
        extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
      };

      systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

      systemd.services.speedtest-metrics = {
        description = "Measure WAN throughput and publish it for the node exporter";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          # Ookla's CLI persists its licence acceptance under $HOME; without a writable
          # one it fails on a read-only /root.
          HOME = "/var/lib/speedtest-metrics";
          SPEEDTEST_BIN = lib.getExe pkgs.ookla-speedtest;
          TEXTFILE_DIR = textfileDir;
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe speedtest-metrics;
          StateDirectory = "speedtest-metrics";
          MemoryMax = "512M";
          # Comfortably longer than a test (~40s) without letting a wedged run linger.
          TimeoutStartSec = "5min";
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };

      systemd.timers.speedtest-metrics = {
        description = "WAN throughput measurement, every 20 minutes";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/20";
          RandomizedDelaySec = "2m";
          # Catch up after the host has been down, rather than silently skipping a slot.
          Persistent = true;
          AccuracySec = "1m";
          Unit = "speedtest-metrics.service";
        };
      };
    };
}
