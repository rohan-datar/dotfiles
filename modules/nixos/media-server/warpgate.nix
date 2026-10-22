{ config, ... }:
let
  topology = config.flake.meta.topology;
in
{
  # A clientless bastion that hands out browser-based SSH, VNC and
  # HTTP sessions to hosts which stay LAN-only.
  flake.modules.nixos.warpgate =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Remove once nixpkgs ships Warpgate >= 0.30.0.
      wgPkg = pkgs.warpgate.overrideAttrs (finalAttrs: previousAttrs: {
        version = "0.30.0";
        src = pkgs.fetchFromGitHub {
          owner = "warp-tech";
          repo = "warpgate";
          tag = "v${finalAttrs.version}";
          hash = "sha256-kWBCKSBK7gAvO3x7l47CNoyQ0K9eY9d3Fq1fM95qAWQ=";
        };
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (finalAttrs) pname version src;
          hash = "sha256-SZyw188Ut/FQ8H+NqzKoMiTLxggymGuxL0QqD3WmPyA=";
        };
        passthru = previousAttrs.passthru // {
          webUi = previousAttrs.passthru.webUi.overrideAttrs {
            inherit (finalAttrs) version src;
            npmDeps = previousAttrs.passthru.webUi.npmDeps.overrideAttrs {
              inherit (finalAttrs) src;
              outputHash = "sha256-jeNoQ884pv3mfigZ7srLSVMFbvE04zXd/2XxqN5t0LI=";
            };
          };
        };
        preBuild = ''
          rm -rf .cargo/
          ln -rs "${finalAttrs.passthru.webUi}" warpgate-web/dist
        '';
      });

      # Warpgate cannot read secrets from the environment or from a file
      # (warp-tech/warpgate#1195), and the nixpkgs module renders `settings`
      # into the world-readable Nix store — so a literal client secret here
      # would leak both into the store and into git. Instead the store copy
      # carries a placeholder, and the real value is substituted into the
      # state-dir copy at start, out of a systemd credential.
      #
      # The substitution has to happen after the module's own ExecStartPre,
      # which rewrites /var/lib/warpgate/config.yaml from the store on every
      # start. Adding a second ExecStartPre is not possible — serviceConfig
      # options conflict rather than merge — so this wraps ExecStart instead,
      # which costs one reconstructed line of upstream logic rather than a copy
      # of its whole init script.
      ssoSecretPlaceholder = "@SSO_CLIENT_SECRET@";
      startWithSsoSecret = pkgs.writeShellScript "warpgate-start" ''
        set -euo pipefail
        umask 077
        secret=$(< "$CREDENTIALS_DIRECTORY/ssoClientSecret")
        config=$(< /var/lib/warpgate/config.yaml)
        printf '%s\n' "''${config//${ssoSecretPlaceholder}/$secret}" \
          > /var/lib/warpgate/config.yaml
        exec ${lib.getExe wgPkg} --config /var/lib/warpgate/config.yaml run
      '';
    in
    {
      age.secrets.warpgate-sso-secret.file = ../../../secrets/warpgate-sso-secret.age;

      services.warpgate = {
        enable = true;
        package = wgPkg;

        settings = {
          external_host = "portal.rdatar.com";

          http = {
            listen = "[::]:8888";

            external_host = "portal.rdatar.com";

            external_port = 443;

            trust_x_forwarded_headers = true;
          };

          ssh.enable = false;

          sso_providers = [
            {
              name = "keycloak";
              label = "Keycloak";

              auto_create_users = false;

              # Pins the SSO return URL to the public name, so a login started
              # against any other host header cannot redirect the callback.
              return_domain_whitelist = [ "portal.rdatar.com" ];

              provider = {
                type = "custom";
                client_id = "warpgate";
                client_secret = ssoSecretPlaceholder;
                issuer_url = topology.identity.issuerUrl;
                # Warpgate matches the OIDC identity to a Warpgate user by
                # email, so `email` is load-bearing, not decorative.
                scopes = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
            }
          ];
        };
      };

      systemd.services.warpgate.serviceConfig = {
        LoadCredential = lib.mkForce "ssoClientSecret:${config.age.secrets.warpgate-sso-secret.path}";
        ExecStart = lib.mkForce startWithSsoSecret;
      };

      # LAN only
      networking.firewall.interfaces.enp1s0.allowedTCPPorts = [ 8888 ];
    };
}
