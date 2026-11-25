{ inputs, ... }:
{
  # iLO 4 OCSD thermal bridge for the Tesla P100 (ml350-physical, 2026-11-25).
  # iLO 4 cannot read a non-HPE GPU, so the chassis fans never ramp for it. The
  # bridge publishes the P100's temperature into the firmware Option Card Sensor
  # Data ($OCS) table as a synthetic slot-3 record ("27-PCI 3" in iLO) that stock
  # iLO fan control acts on. Qualified with 140 W and llm-bench phase-a-4 on
  # 2026-11-24 (Org: history/omp-continuation-2026-10-24/ml350-installation.org).
  # After any power cycle, reset iLO once so it registers 27-PCI 3.
  flake.modules.nixos.ocsd-thermal-bridge = {
    imports = [ inputs.gen9-t4-ocsd.nixosModules.default ];

    services.gen9-t4-ocsd = {
      enable = true;
      # Publish GPU+10 so iLO's fan curve engages earlier: without it the fans
      # peaked at ~47% duty and the Q3_K_M case tripped 78 C at 140 W.
      publishOffset = 10;
      # GPU work is k3s pods, not host units: keep the module's no-op placeholder.
      workloadUnits = [ ];
    };

    systemd.services.gen9-t4-ocsd = {
      after = [ "nvidia-power-cap.service" ];
      # A dead publisher leaves iLO holding the fans at 100%; page once systemd
      # gives up restarting it (template from the auto-upgrade aspect).
      onFailure = [ "ntfy-failure@%n.service" ];
    };
  };
}
