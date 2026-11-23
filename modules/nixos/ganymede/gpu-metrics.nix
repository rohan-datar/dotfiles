_:
{
  # GPU telemetry for Prometheus (ml350-physical, 2026-11-23): the proprietary NVIDIA driver's
  # temperature isn't visible to node_exporter's hwmon collector, and iLO 4 can't see a
  # non-HPE GPU, so there was no GPU temperature history at all. A tiny sampler writes
  # nvidia-smi readings to node_exporter's textfile collector every 10 s (no DCGM for one P100).
  flake.modules.nixos.gpu-metrics =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      textfileDir = "/var/lib/prometheus-node-exporter-text-files";
      smi = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
      fields = "index,uuid,name,temperature.gpu,power.draw,power.limit,enforced.power.limit,clocks.sm,clocks.mem,memory.used,memory.total,utilization.gpu,fan.speed,clocks_event_reasons.active";
      sampler = pkgs.writeShellScript "nvidia-gpu-textfile" ''
        set -u
        out=${textfileDir}/nvidia_gpu.prom
        while true; do
          tmp=$(${pkgs.coreutils}/bin/mktemp ${textfileDir}/.nvidia_gpu.XXXXXX)
          {
            echo "# HELP nvidia_gpu_up 1 if nvidia-smi answered on the last sample."
            echo "# TYPE nvidia_gpu_up gauge"
            if lines=$(${smi} --query-gpu=${fields} --format=csv,noheader,nounits 2>/dev/null); then
              echo "nvidia_gpu_up 1"
              echo "$lines" | ${pkgs.gawk}/bin/awk -F', *' '
                function num(v) { return (v ~ /^[0-9.]+$/) ? v : "NaN" }
                {
                  l = sprintf("gpu=\"%s\",uuid=\"%s\",name=\"%s\"", $1, $2, $3)
                  printf "nvidia_gpu_temperature_celsius{%s} %s\n", l, num($4)
                  printf "nvidia_gpu_power_draw_watts{%s} %s\n", l, num($5)
                  printf "nvidia_gpu_power_limit_watts{%s} %s\n", l, num($6)
                  printf "nvidia_gpu_enforced_power_limit_watts{%s} %s\n", l, num($7)
                  printf "nvidia_gpu_sm_clock_hertz{%s} %s\n", l, (num($8) == "NaN" ? "NaN" : $8 * 1e6)
                  printf "nvidia_gpu_memory_clock_hertz{%s} %s\n", l, (num($9) == "NaN" ? "NaN" : $9 * 1e6)
                  printf "nvidia_gpu_memory_used_bytes{%s} %s\n", l, (num($10) == "NaN" ? "NaN" : $10 * 1048576)
                  printf "nvidia_gpu_memory_total_bytes{%s} %s\n", l, (num($11) == "NaN" ? "NaN" : $11 * 1048576)
                  printf "nvidia_gpu_utilization_ratio{%s} %s\n", l, (num($12) == "NaN" ? "NaN" : $12 / 100)
                  printf "nvidia_gpu_fan_speed_ratio{%s} %s\n", l, (num($13) == "NaN" ? "NaN" : $13 / 100)
                  mask = strtonum($14)
                  printf "nvidia_gpu_clock_event_reasons{%s} %d\n", l, mask
                  split("gpu_idle applications_clocks sw_power_cap hw_slowdown sync_boost sw_thermal hw_thermal hw_power_brake", r, " ")
                  for (i = 1; i <= 8; i++)
                    printf "nvidia_gpu_clock_event_active{%s,reason=\"%s\"} %d\n", l, r[i], and(mask, 2^(i-1)) ? 1 : 0
                }'
            else
              echo "nvidia_gpu_up 0"
            fi
          } > "$tmp"
          ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
          ${pkgs.coreutils}/bin/mv -f "$tmp" "$out"
          ${pkgs.coreutils}/bin/sleep 10
        done
      '';
    in
    {
      services.prometheus.exporters.node = {
        enabledCollectors = [ "textfile" ];
        extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
      };
      systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

      systemd.services.nvidia-gpu-textfile = {
        description = "NVIDIA GPU telemetry for node_exporter's textfile collector";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        serviceConfig = {
          ExecStart = sampler;
          Restart = "always";
          RestartSec = 10;
          Nice = 10;
          # Read-only telemetry: no power/clock changes from this unit.
          ProtectSystem = "strict";
          ReadWritePaths = [ textfileDir ];
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    };
}
