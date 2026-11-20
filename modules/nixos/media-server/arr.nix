{ config, inputs, ... }:
let
  topology = config.flake.meta.topology;
in
{
  flake.modules.nixos.arr = {
    imports = [
      inputs.nixarr.nixosModules.default
      (
        { config, pkgs, ... }:
        {
          age.secrets.wgconf.file = ../../../secrets/AirVPN-America-WG.conf.age;
          age.secrets.qui-env.file = ../../../secrets/qui-env.age;

          nixarr = {
            enable = true;

            vpn = {
              enable = true;
              wgConf = config.age.secrets.wgconf.path;
              accessibleFrom = [ "10.10.0.0/19" ];
            };
            mediaDir = topology.mediaStorage.mountPoint;

            jellyfin = {
              enable = true;
              openFirewall = true;
            };

            qbittorrent = {
              enable = true;
              vpn.enable = true;
              openFirewall = true;
              peerPort = 21209;
              qui.enable = true;
              extraConfig = {
                Preferences = {
                  "WebUI\\Password_PBKDF2" =
                    ''"@ByteArray(AcS/eSauZc8rMTFhenysTA==:woLHoXoRKxq/v3SyNB3HAL+SZKz1icLlHVzRrV54m8mJOdlt/xu9M2n+slobkmSb81m/G7h8o+/bzR4Ozn+BhQ==)"'';
                };
              };
            };
          };

          # nixarr's nixarr-py pins a Jellyfin OpenAPI spec hash per Jellyfin version and
          # stops at 12.2, so evaluation fails on nixpkgs' Jellyfin 12.4. Rebuild it from
          # nixarr's own sources, supplying the 12.4 spec hash. Removed with nixarr in Wave 4.
          nixarr.nixarr-py.package =
            let
              nixarrPy = "${inputs.nixarr}/nixarr/lib/nixarr-py";
              jellyfinOpenApiHash = "sha256-AqYGSRa34I8fHY1//B+xx2I98ON4cp/Nf9NTdmhoA24="; # 12.4
            in
            pkgs.python3Packages.buildPythonPackage {
              pname = "nixarr-py";
              version = "0.1.0";
              pyproject = true;
              src = nixarrPy;
              build-system = [ pkgs.python3Packages.setuptools ];
              dependencies = pkgs.callPackage "${nixarrPy}/python-deps.nix" {
                jellyfin = config.nixarr.jellyfin.package;
                # The spec is python-deps.nix's only fetchurl; replace its version-keyed hash.
                fetchurl = args: pkgs.fetchurl (removeAttrs args [ "hash" ] // { hash = jellyfinOpenApiHash; });
              };
            };

          systemd.services.jellyfin.environment = {
            VDPAU_DRIVER = "va_gl";
            LIBVA_DRIVER_NAME = "iHD";
          };
          systemd.services.qui.serviceConfig.EnvironmentFile = config.age.secrets.qui-env.path;
        }
      )
    ];
  };
}
