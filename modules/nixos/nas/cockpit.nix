_: {
  flake.modules.nixos.nas-cockpit =
    { pkgs, ... }:
    {
      # Read-mostly ZFS dashboard (45Drives plugin). Destructive ops stay in the
      # runbook — the plugin was written for 45Drives' Ubuntu appliances, so
      # don't trust its write-path buttons until proven on NixOS.
      services.cockpit = {
        enable = true;
        port = 9090;
        plugins = [ pkgs.cockpit-zfs ];
      };

      # LAN interface only; openFirewall would open every interface.
      networking.firewall.interfaces.enp2s0.allowedTCPPorts = [ 9090 ];
    };
}
