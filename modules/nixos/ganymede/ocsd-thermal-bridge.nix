_: {
  # iLO 4 OCSD thermal bridge for the Tesla P100 (ml350-physical, 2026-11-25).
  # iLO 4 cannot read a non-HPE GPU, so the chassis fans never ramp for it. This
  # daemon publishes the P100's temperature into the firmware Option Card Sensor
  # Data ($OCS) table in host memory as a synthetic slot-3 record, which iLO shows
  # as "27-PCI 3" and feeds into its stock fan control. Fork of
  # oceanmedianow/gen9-t4-ocsd-thermal-bridge (MIT), adapted for the ML350 Gen9 +
  # P100 and qualified under llm-bench phase-a-4 on 2026-11-24 (Org:
  # history/omp-continuation-2026-10-24/ml350-installation.org).
  flake.modules.nixos.ocsd-thermal-bridge =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      bridge = pkgs.stdenvNoCC.mkDerivation {
        pname = "gen9-t4-ocsd";
        version = "0-unstable-2026-11-24";
        src = pkgs.fetchFromGitHub {
          owner = "rohan-datar";
          repo = "gen9-t4-ocsd-thermal-bridge";
          rev = "9fcbc01fa31ed059ceaeecba682f5576869e9247"; # branch ml350-p100-publish-offset
          hash = "sha256-1U8snUdZ1JOFCE+A99wcGmrnBusUU1n0AgWVfhCI4co=";
        };
        dontBuild = true;
        doCheck = true;
        nativeCheckInputs = [ pkgs.python3 ];
        # Offline protocol tests: record layout, checksums, claim/restore, offset.
        checkPhase = ''
          runHook preCheck
          python3 -m unittest discover -s tests
          runHook postCheck
        '';
        installPhase = ''
          runHook preInstall
          install -Dm0444 gen9_t4_ocsd.py $out/libexec/gen9-t4-ocsd/gen9_t4_ocsd.py
          install -Dm0444 LICENSE $out/share/doc/gen9-t4-ocsd/LICENSE
          runHook postInstall
        '';
      };
      # The daemon stops these units before giving up its OCSD slot or on a thermal
      # trip (>= 82 C, telemetry loss). GPU work here is k3s pods, which are not host
      # units, so nothing is wired to it yet: the placeholder only satisfies the
      # daemon's start-up check. Thermal protection under load is the llm-bench Job
      # guard (80 C), driver slowdown (82 C) and shutdown (85 C).
      workloadUnit = "ocsd-gpu-workload.service";
    in
    {
      # In-band IPMI (/dev/ipmi0) for the daemon's iLO sensor check and for
      # operator checks: ipmitool sdr list | grep -E '^(27-PCI|Fan)'.
      boot.kernelModules = [
        "ipmi_devintf"
        "ipmi_si"
      ];
      environment.systemPackages = [ pkgs.ipmitool ];

      systemd.services.ocsd-gpu-workload = {
        description = "Placeholder for GPU workloads the OCSD bridge may stop";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
        };
      };

      systemd.services.gen9-t4-ocsd = {
        description = "iLO 4 OCSD thermal bridge for the Tesla P100";
        wantedBy = [ "multi-user.target" ];
        after = [
          "nvidia-persistenced.service"
          "nvidia-power-cap.service"
        ];
        wants = [ "nvidia-persistenced.service" ];
        # Repeated crashes leave the record stale, and iLO then holds the fans at
        # 100%: loud but safe. Page when systemd gives up restarting it.
        onFailure = [ "ntfy-failure@%n.service" ];
        startLimitIntervalSec = 300;
        startLimitBurst = 5;
        environment = {
          OCSD_NVIDIA_SMI = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
          OCSD_IPMITOOL = lib.getExe pkgs.ipmitool;
          OCSD_SYSTEMCTL = "${config.systemd.package}/bin/systemctl";
          OCSD_WORKLOAD_UNITS = workloadUnit;
          OCSD_ILO_SENSOR = "27-PCI 3";
          # Publish GPU+10 so iLO's fan curve engages earlier (fans peaked at ~47%
          # duty without it and the Q3_K_M case tripped 78 C at 140 W). iLO displays
          # the record +15, so its reading is GPU+25.
          OCSD_PUBLISH_OFFSET_C = "10";
          OCSD_ILO_OFFSET_C = "25";
        };
        serviceConfig = {
          # Type=exec, not upstream's notify: the daemon sends READY only after iLO
          # confirms the sensor, which after a power cycle needs a manual iLO reset.
          # notify would hold boot and nixos-rebuild switch in "activating", then
          # time out and restart-loop. The daemon still publishes (and the
          # watchdog still applies) before iLO confirms; READY's STATUS text shows
          # in systemctl status once it does.
          Type = "exec";
          NotifyAccess = "main";
          ExecStart = "${lib.getExe pkgs.python3} ${bridge}/libexec/gen9-t4-ocsd/gen9_t4_ocsd.py";
          Restart = "on-failure";
          RestartSec = 3;
          # One loop can block ~19 s (15 s IPMI timeout + 4 s nvidia-smi).
          WatchdogSec = 60;
          # Shutdown publishes cooldown for up to 90 s before restoring the table.
          TimeoutStopSec = 150;
          StateDirectory = "gen9-t4-ocsd";
          StateDirectoryMode = "0700";
          RuntimeDirectory = "gen9-t4-ocsd";
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          RestrictAddressFamilies = [ "AF_UNIX" ];
          DevicePolicy = "closed";
          DeviceAllow = [
            "/dev/mem rw"
            "/dev/ipmi0 rw"
            "/dev/nvidia0 rw"
            "/dev/nvidiactl rw"
            "/dev/nvidia-uvm rw"
          ];
          MemoryMax = "128M";
          TasksMax = 32;
        };
      };
    };
}
