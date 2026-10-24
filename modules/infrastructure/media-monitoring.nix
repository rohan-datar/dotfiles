{ lib, config, ... }:
let
  # The direct media liveness relationship: Gatus on home-controller probes
  # each app on home-media directly, bypassing Caddy and oauth2-proxy.
  topology = config.flake.meta.topology;

  # Every probe pushes on the same policy, so name the list once.
  ntfy = [ { type = "ntfy"; } ];

  # Direct liveness probe of an HTTP app's unauthenticated /ping endpoint.
  # Carries both the port (for the firewall) and the Gatus endpoint, so the
  # port is only maintained once.
  httpProbe = name: port: {
    inherit name port;
    endpoint = {
      group = "media-ingress";
      interval = "120s";
      url = "http://${topology.hosts.home-media.lanAddress}:${toString port}/ping";
      conditions = [ "[STATUS] == 200" ];
      alerts = ntfy;
    };
  };

  # Direct TCP liveness probe for apps without an unauthenticated /ping
  # endpoint (Bazarr, Shelfmark).
  tcpProbe = name: port: {
    inherit name port;
    endpoint = {
      group = "media-ingress";
      interval = "120s";
      url = "tcp://${topology.hosts.home-media.lanAddress}:${toString port}";
      conditions = [ "[CONNECTED] == true" ];
      alerts = ntfy;
    };
  };

  # The five direct media probes, in canonical order.
  mediaProbes = [
    (httpProbe "sonarr-app" 8989)
    (httpProbe "radarr-app" 7878)
    (httpProbe "prowlarr-app" 9696)
    (tcpProbe "bazarr-app" 6767)
    (tcpProbe "shelfmark-app" 8084)
  ];

  # Ports the controller's Gatus probes and OPNsense Caddy need on home-media.
  probePorts = lib.concatStringsSep "," (
    map toString (lib.sort (a: b: a < b) (map (p: p.port) mediaProbes))
  );

  # Ports the Home Assistant Sonarr and Radarr integrations poll on home-media.
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
    '';
  };
}
