# Rohan's Nix Configuration

This repository contains a comprehensive Nix configuration for managing both NixOS (Linux) and nix-darwin (macOS) systems using the modern flake-parts framework. The configuration is designed to be modular, maintainable, and easily extendable.

## Overview

This configuration uses:

- [Nix Flakes](https://nixos.wiki/wiki/Flakes) for reproducible builds and dependencies
- [flake-parts](https://github.com/hercules-ci/flake-parts) for a modular flake structure
- [Home Manager](https://github.com/nix-community/home-manager) for user environment configuration
- [nix-darwin](https://github.com/LnL7/nix-darwin) for macOS system configuration
- [easy-hosts](https://github.com/tgirlcloud/easy-hosts) for simplified host management

## System Structure

The configuration is organized into several key directories:

- `flake.nix`: Entry point for the Nix flake
- `hosts/`: Host-specific configurations
  - `home-desktop/`: NixOS desktop configuration
  - `macbook/`: Darwin (macOS) configuration
- `home/`: Home Manager user configurations
  - `rdatar/`: Linux user configuration
  - `rohandatar/`: macOS user configuration
- `modules/`: Shared configuration modules
  - `darwin/`: Darwin-specific modules
  - `flake/`: Flake-related modules
  - `global/`: Some global modules and helpers
  - `home/`: Home Manager modules
  - `nixos/`: NixOS-specific modules
  - `shared/`: Modules shared across all systems
- `secrets/`: Encrypted secrets using Agenix

This takes heavy inspiration from [isabelroses' dotfiles](https://github.com/isabelroses/dotfiles)

## Temporary security overrides

`modules/nixos/_packages/nodejs-security.nix` pins the October 21, 2026
security releases (Node.js 22.23.4 and 24.22.1) for Seerr, Homepage, Vicinae, and the
desktop's Node CLI without globally rebuilding unrelated Node consumers.
Remove these scoped overrides once nixpkgs-unstable supplies those fixes.
`modules/nixos/default.nix` blacklists emSign ECC Root CA - G3 in the system CA
bundle and sets `NIX_SSL_CERT_FILE` to that bundle for every systemd service and
login shell, so Python `certifi` uses it instead of its own `cacert.pem`. Remove
the variable once nixpkgs ships certifi 2026.10.19 or later, and the blacklist
once nixpkgs `cacert` drops the root.
LDAP ACME DNS-01 propagation checks use an external resolver because the
LAN's private wildcard masks the public challenge records.
