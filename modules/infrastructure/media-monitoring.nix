_:
let
  # The direct media liveness relationship (ADR 0008): Gatus on callisto probes
  # each k3s media app directly through Cilium's internal Gateway VIP (10.10.2.20,
  # restricted to HA + callisto), bypassing OPNsense Caddy and Authelia forward-auth.
  internalGatewayVip = "10.10.2.20";

  # Every probe pushes on the same policy, so name the list once.
  ntfy = [ { type = "ntfy"; } ];

  k8sHttpProbe = name: host: path: {
    inherit name;
    group = "media-ingress";
    interval = "120s";
    url = "http://${internalGatewayVip}${path}";
    headers.Host = host;
    conditions = [ "[STATUS] == 200" ];
    alerts = ntfy;
  };

  # The five direct media probes, in canonical order.
  mediaProbes = [
    (k8sHttpProbe "sonarr-app" "tv.media.rdatar.com" "/ping")
    (k8sHttpProbe "radarr-app" "movie.media.rdatar.com" "/ping")
    (k8sHttpProbe "prowlarr-app" "trackers.media.rdatar.com" "/ping")
    (k8sHttpProbe "bazarr-app" "subtitles.media.rdatar.com" "/ping")
    (k8sHttpProbe "shelfmark-app" "shelfmark.media.rdatar.com" "/api/health")
  ];
in
{
  flake.modules.nixos.media-probes = _: {
    services.gatus.settings.endpoints = mediaProbes;
  };
}
