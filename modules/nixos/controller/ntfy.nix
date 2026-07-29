_: {
  # Self-hosted push notifications. Gatus posts alerts here over loopback; the
  # phone subscribes through the public vhost (OPNsense Caddy → br0:2586).
  #
  # Port 2586 is ntfy's upstream default and is free on this host — the busy
  # ports here are 8080 (Keycloak), 8081 (Gatus), 3000 (Grafana), 3890/17170
  # (lldap), 9090 (cockpit), 9091 (Prometheus) and 9100 (node_exporter).
  # Keeping upstream's default means the CLI and the docs need no translation.
  flake.modules.nixos.ntfy = _: {
    services.ntfy-sh = {
      enable = true;

      settings = {
        base-url = "https://ntfy.datars.org";

        # All interfaces, deliberately: Gatus posts to 127.0.0.1:2586 (no
        # hairpin through the public vhost) while OPNsense reaches br0. The
        # firewall rule below is what actually scopes exposure to the LAN.
        listen-http = ":2586";

        # OPNsense's Caddy terminates TLS in front, so trust its forwarded
        # client address for rate limiting.
        behind-proxy = true;

        # iOS has no background sockets, so self-hosted servers relay a
        # content-free poll request through ntfy.sh's APNs app; the phone then
        # fetches the real message from us. Requires base-url to be set.
        upstream-base-url = "https://ntfy.sh";

        # Nothing is readable or publishable without credentials. Users and
        # tokens are created imperatively against this file (`ntfy user add` /
        # `ntfy token add`) — the CLI finds it via /etc/ntfy/server.yml.
        auth-file = "/var/lib/ntfy-sh/user.db";
        auth-default-access = "deny-all";

        # A day of replay, so a phone that was off-network still gets the
        # backlog when it reconnects.
        cache-duration = "24h";
      };
    };

    # LAN only; the public ntfy.datars.org vhost lives on OPNsense.
    networking.firewall.interfaces.br0.allowedTCPPorts = [ 2586 ];
  };
}
