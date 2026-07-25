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
        # Cockpit drops any websocket whose Origin isn't listed here (the module
        # only adds https://localhost:9090), which kills the session right after
        # login. Cover direct-IP access and the Caddy vhost.
        allowed-origins = [
          "https://10.10.1.10:9090"
          "wss://10.10.1.10:9090"
          "https://store.rdatar.com"
          "wss://store.rdatar.com"
        ];
        settings.WebService = {
          # Caddy terminates TLS and proxies plain http; without this cockpit
          # redirects http→https and Firefox loops. LAN-only exposure.
          AllowUnencrypted = true;
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
        };
      };

      # LAN interface only; openFirewall would open every interface.
      networking.firewall.interfaces.enp2s0.allowedTCPPorts = [ 9090 ];
    };
}
