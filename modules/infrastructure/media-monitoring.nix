{ lib, config, ... }:
let
  # The direct media liveness relationship (ADR 0008): Gatus on home-controller probes
  # each app directly, bypassing OPNsense Caddy and Authelia forward-auth.
  # Native apps on europa are probed on their host ports; k3s-migrated apps are probed
  # through Cilium's internal Gateway VIP (10.10.2.20, restricted to HA + home-controller).
  topology = config.flake.meta.topology;
  internalGatewayVip = "10.10.2.20";

  # Every probe pushes on the same policy, so name the list once.
  ntfy = [ { type = "ntfy"; } ];

  # Direct liveness probe of a native HTTP app's unauthenticated /ping endpoint on europa.
  httpProbe = name: port: {
    inherit name port;
    endpoint = {
      group = "media-ingress";
      interval = "120s";
      url = "http://${topology.hosts.europa.lanAddress}:${toString port}/ping";
      conditions = [ "[STATUS] == 200" ];
      alerts = ntfy;
    };
  };

  # Direct TCP liveness probe for native apps without an unauthenticated /ping endpoint.
  tcpProbe = name: port: {
    inherit name port;
    endpoint = {
      group = "media-ingress";
      interval = "120s";
      url = "tcp://${topology.hosts.europa.lanAddress}:${toString port}";
      conditions = [ "[CONNECTED] == true" ];
      alerts = ntfy;
    };
  };

  # Direct HTTP liveness probe via k3s gateway/internal (no host port opened on europa).
  k8sHttpProbe = name: host: path: {
    inherit name;
    port = null;
    endpoint = {
      group = "media-ingress";
      interval = "120s";
      url = "http://${internalGatewayVip}${path}";
      headers.Host = host;
      conditions = [ "[STATUS] == 200" ];
      alerts = ntfy;
    };
  };

  # The five direct media probes, in canonical order.
  mediaProbes = [
    (httpProbe "sonarr-app" 8989)
    (httpProbe "radarr-app" 7878)
    (httpProbe "prowlarr-app" 9696)
    (tcpProbe "bazarr-app" 6767)
    (k8sHttpProbe "shelfmark-app" "shelfmark.media.rdatar.com" "/api/health")
  ];

  # Ports the controller's Gatus probes and OPNsense Caddy still need on europa.
  probePorts = lib.concatStringsSep "," (
    map toString (lib.sort (a: b: a < b) (lib.filter (p: p != null) (map (p: p.port) mediaProbes)))
  );

  # Ports the Home Assistant Sonarr and Radarr integrations poll on europa.
  homeAssistantPorts = "7878,8989";
in
{
  flake.modules.nixos.media-probes = _: {
    services.gatus.settings.endpoints = map (p: { inherit (p) name; } // p.endpoint) mediaProbes;
  };

  flake.modules.nixos.media-probe-access = _: {
    networking.firewall.extraCommands = ''
      iptables -w -A nixos-fw -p tcp -m multiport --dports ${probePorts} \
        -s ${topology.hosts.home-controller.lanAddress} -m comment --comment "gatus app liveness" \
        -j nixos-fw-accept
      iptables -w -A nixos-fw -p tcp -m multiport --dports ${probePorts} \
        -s ${topology.gatewayAddress} -m comment --comment "opnsense caddy reverse proxy" \
        -j nixos-fw-accept
      iptables -w -A nixos-fw -p tcp -m multiport --dports ${homeAssistantPorts} \
        -s ${topology.hosts.home-assistant.lanAddress} -m comment --comment "home assistant arr integrations" \
        -j nixos-fw-accept
      # Coexistence during the k3s media migration: migrated pods reach the still-native
      # *arr services on europa until Wave 2. Cilium does not masquerade pod traffic to
      # cluster nodes, so it arrives from the pod CIDR (10.42.0.0/16), not a node IP.
      iptables -w -A nixos-fw -p tcp -m multiport --dports ${probePorts} \
        -s 10.42.0.0/16 -m comment --comment "k3s pods -> native media coexistence" \
        -j nixos-fw-accept
    '';
  };
}
