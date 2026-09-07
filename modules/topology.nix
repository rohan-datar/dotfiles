{ lib, config, ... }:
{
  options.flake.meta.topology = lib.mkOption {
    type = lib.types.submodule {
      options = {
        hosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                lanAddress = lib.mkOption {
                  type = lib.types.str;
                  description = "Host's LAN address";
                };
                mediaLinkAddress = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Address on the point-to-point NAS/media link, if the host has one";
                };
              };
            }
          );
          description = "LAN inventory of managed hosts plus infra endpoints";
        };

        gatewayAddress = lib.mkOption {
          type = lib.types.str;
          description = "Default gateway (OPNsense)";
        };

        identity = lib.mkOption {
          type = lib.types.submodule {
            options = {
              hostname = lib.mkOption {
                type = lib.types.str;
                description = "Public hostname of the identity provider (Keycloak)";
              };
              realm = lib.mkOption {
                type = lib.types.str;
                description = "Keycloak realm";
              };
              baseUrl = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = "https://${config.flake.meta.topology.identity.hostname}";
                description = "Derived identity provider base URL";
              };
              issuerUrl = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = "${config.flake.meta.topology.identity.baseUrl}/realms/${config.flake.meta.topology.identity.realm}";
                description = "Derived OIDC issuer URL";
              };
            };
          };
          description = "Identity provider (Keycloak) addressing";
        };

        mediaStorage = lib.mkOption {
          type = lib.types.submodule {
            options = {
              exportPath = lib.mkOption {
                type = lib.types.str;
                description = "Export path on the NAS (home-nas) for the media NFS share";
              };
              mountPoint = lib.mkOption {
                type = lib.types.str;
                description = "Mount point on the consumer (home-media)";
              };
            };
          };
          description = "NAS↔media NFS storage relationship";
        };
      };
    };
    description = "Shared topology inventory: host addresses, gateway, identity provider URLs, media storage paths";
  };

  # The inventory itself. mediaStorage paths live in
  # infrastructure/media-storage.nix so the NAS↔media relationship owns them.
  config.flake.meta.topology = {
    hosts = {
      home-nas = {
        lanAddress = "10.10.1.10";
        mediaLinkAddress = "10.10.100.1";
      };
      home-media = {
        lanAddress = "10.10.1.11";
        mediaLinkAddress = "10.10.100.2";
      };
      home-controller = {
        lanAddress = "10.10.1.13";
      };
      # External HAOS VM endpoint, not a managed flake host.
      home-assistant = {
        lanAddress = "10.10.1.12";
      };
    };
    gatewayAddress = "10.10.0.1";
    identity = {
      hostname = "auth.datars.org";
      realm = "homelab";
    };
  };
}
