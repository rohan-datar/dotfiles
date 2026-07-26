_: {
  # TLS + forward-auth ingress for the Arr stack and qBittorrent, terminated on
  # home-media itself. Pairs with the media-oauth2-proxy aspect.
  flake.modules.nixos.media-ingress =
    { config, ... }:
    let
      # oauth2-proxy's documented Caddy integration, all over loopback.
      protected = port: ''
        route {
        	reverse_proxy /oauth2/* localhost:4180 {
        		header_up X-Real-IP {remote_host}
        		header_up X-Forwarded-Uri {uri}
        	}
        	forward_auth localhost:4180 {
        		uri /oauth2/auth
        		header_up X-Real-IP {remote_host}
        		copy_headers X-Auth-Request-User X-Auth-Request-Email
        		@error status 401
        		handle_response @error {
        			redir * https://{host}/oauth2/sign_in?rd={scheme}://{host}{uri}
        		}
        	}
        	reverse_proxy localhost:${toString port}
        }
      '';
    in
    {
      # CLOUDFLARE_DNS_API_TOKEN for the DNS-01 challenge.
      age.secrets.cloudflare-dns-token.file = ../../../secrets/cloudflare-dns-token.age;

      # One wildcard cert via DNS-01, so Caddy needs no cloudflare plugin build.
      security.acme = {
        acceptTerms = true;
        defaults.email = "me@rdatar.com";
        certs."media.rdatar.com" = {
          domain = "*.media.rdatar.com";
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets.cloudflare-dns-token.path;
          group = "caddy";
        };
      };

      services.caddy = {
        enable = true;
        virtualHosts = {
          # Sonarr
          "tv.media.rdatar.com" = {
            useACMEHost = "media.rdatar.com";
            extraConfig = protected 8989;
          };
          # Radarr
          "movie.media.rdatar.com" = {
            useACMEHost = "media.rdatar.com";
            extraConfig = protected 7878;
          };
          # Prowlarr
          "trackers.media.rdatar.com" = {
            useACMEHost = "media.rdatar.com";
            extraConfig = protected 9696;
          };
          # Bazarr
          "subtitles.media.rdatar.com" = {
            useACMEHost = "media.rdatar.com";
            extraConfig = protected 6767;
          };
        };
      };

      networking.firewall.interfaces.enp1s0.allowedTCPPorts = [
        80
        443
      ];
    };
}
