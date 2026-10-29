{ pkgs }:
let
  inherit (pkgs) lib;
  # Remove this override once nixpkgs-unstable ships Node.js 24.22.1 or later.
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
  nodejs-slim_24 =
    patchNode pkgs.nodejs-slim_24 "24.22.1"
      "4f5379796280cdaeb0c2f358fd04b6a16cc4fb7dfa83b5a8c91a9d963b435231";
in
{
  nodejs_24 = pkgs.nodejs_24.override { nodejs-slim = nodejs-slim_24; };
}
