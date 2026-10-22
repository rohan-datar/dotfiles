{ pkgs }:
let
  inherit (pkgs) lib;
  # Remove these overrides once nixpkgs-unstable ships 22.23.4 and 24.22.1.
  # Source hashes are from nodejs.org/dist/v${version}/SHASUMS256.txt.
  # These releases use Brotli error codes that the nixpkgs Brotli 1.2.0
  # headers lack, so build Node's vendored Brotli instead of the shared one.
  patchNode =
    package: version: sha256:
    package.overrideAttrs (old: {
      inherit version;
      src = pkgs.fetchurl {
        url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
        inherit sha256;
      };
      configureFlags = lib.filter (flag: !lib.hasPrefix "--shared-brotli" flag) old.configureFlags;
    });
  nodejs-slim_22 =
    patchNode pkgs.nodejs-slim_22 "22.23.4"
      "7b9adc82d612d0a2a863d96c46de2292552e250cee51956ebbe0146c42aacae9";
  nodejs-slim_24 =
    patchNode pkgs.nodejs-slim_24 "24.22.1"
      "4f5379796280cdaeb0c2f358fd04b6a16cc4fb7dfa83b5a8c91a9d963b435231";
in
{
  inherit nodejs-slim_22;
  nodejs_24 = pkgs.nodejs_24.override { nodejs-slim = nodejs-slim_24; };
}
