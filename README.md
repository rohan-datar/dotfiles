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
