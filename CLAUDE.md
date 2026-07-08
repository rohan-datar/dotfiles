# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A NixOS/nix-darwin flake configuration managing three hosts across Linux and macOS, built on flake-parts and easy-hosts.

## Key Commands

```bash
# Format all files (nixfmt, shfmt, stylua, deadnix, statix, keep-sorted)
nix fmt

# Evaluate flake without building (catches syntax/type errors)
nix flake check --no-build

# Rebuild and switch the current system (formats, checks, rebuilds, auto-commits)
nix run .#nx -- switch    # or just: nx switch

# Update all flake inputs, then rebuild
nix run .#nx -- update

# Build a specific host without switching
nix build .#nixosConfigurations.home-desktop.config.system.build.toplevel
nix build .#nixosConfigurations.home-media.config.system.build.toplevel
nix build .#darwinConfigurations.Rohans-MacBook.config.system.build.toplevel
```

## Architecture

### Flake Entry Point

`flake.nix` delegates everything to flake-parts via `inputs.import-tree ./modules`. Every file under `modules/` is a flake-parts module. Features are exposed as aspects through the `flake.modules.<class>.<name>` namespace, contributed by the files in `modules/`.

The flake modules in `modules/flake/` define:
- `args.nix` — overlays and system configuration
- `formatter.nix` — treefmt with nixfmt, deadnix, statix, shfmt, shellcheck, stylua, keep-sorted
- `modules.nix` — enables the `flake.modules.*` namespace
- `packages/` — the `nx` helper script

### Host Management (easy-hosts)

Hosts are defined in `modules/hosts.nix` with class and tags:

| Host | Class | Arch | Role |
|------|-------|------|------|
| **home-desktop** | nixos | x86_64 | Desktop (Hyprland/Niri, NVIDIA) |
| **home-media** | nixos | x86_64 | Media server (arr stack, Jellyfin) — no home-manager |
| **Rohans-MacBook** | darwin | aarch64 | MacBook (Aerospace, Homebrew) |

`perClass` applies `self.modules.<class>.default`. Each host dir (`hosts/{name}/`) has `default.nix` plus `hardware-configuration.nix` and `user.nix` where applicable; everything else is opted into by importing aspects (e.g. `self.modules.nixos.graphical`, `self.modules.nixos.rdatar`).

### Module Hierarchy

```
modules/
  meta.nix          — the only custom option: flake.meta.defaults (default programs)
  hosts.nix         — easy-hosts configuration
  home-manager.nix  — flake.modules.{nixos,darwin}.home-manager aspect (imported by graphical umbrellas only)
  users/            — per-user OS account aspects (flake.modules.nixos.rdatar, flake.modules.darwin.rohandatar)
  shared/           — generic.shared aspect applied to all hosts (base, nixpkgs, variables)
  nixos/            — NixOS-only aspects (hardware, graphical, system, services)
  darwin/           — macOS-only aspects (system prefs, homebrew, nix settings)
  home/             — Home Manager aspects; per-user configs in _{username}/ (import-tree-skipped plain HM modules)
  flake/            — flake-parts plumbing (formatter, packages, args, modules)
```

### Aspects

Features are organized as aspects under `flake.modules.<class>.<name>`. Hosts opt in by importing the relevant aspect (e.g. `self.modules.nixos.graphical`). Feature enablement is **import-based**: there are no enable flags — importing an aspect enables it. The only custom option is `flake.meta.defaults` (flake-level, `modules/meta.nix`); Home Manager aspect files read it by closing over the flake-parts `config` at the top of the file.

### Home Manager Integration

Home Manager is a graphical-host concern: `flake.modules.<class>.home-manager` (in `modules/home-manager.nix`) is imported by the `graphical` umbrella aspects, with `useGlobalPkgs = true` and `useUserPackages = true`. Server hosts have **no home-manager** — they get self-contained wrapped tools (`modules/wrapped/`) via `server-base` instead. Per-user configs live in `modules/home/_{username}/` (underscore-prefixed so import-tree skips them; the files inside are plain HM modules), exposed as `flake.modules.homeManager.{username}` by `modules/home/users.nix` and attached in each host's `user.nix` (`home-manager.users.<name>.imports`).

### Secrets

Managed with Agenix. Encrypted `.age` files in `secrets/`. Never commit plaintext secrets.

## Conventions

- **Formatter**: Always run `nix fmt` before committing. The `nx switch` command does this automatically.
- **keep-sorted**: Lists marked with `# keep-sorted start` / `# keep-sorted end` are auto-sorted by the formatter. Add new items anywhere in the block; they'll be sorted on format.
- **Module pattern**: New modules should define `flake.modules.<class>.<name>` aspects. Never use `pkgs`, `config`, or `osConfig` at the top-level flake-parts function — those belong inside the aspect value.
- **Conditional config**: Gate features by import, not flags — graphical-only settings belong in aspects imported by the `graphical` umbrellas. Use `_class` checks for NixOS vs Darwin differences when a single file defines both classes, and `pkgs.stdenv.hostPlatform` checks for platform differences inside Home Manager modules.
- **CI**: Pushes trigger `nix flake check --all-systems` on both Linux and macOS runners. Flake lock is auto-updated on a schedule (Tue/Thu) with auto-merge after checks pass.
