# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What This Is

A NixOS/nix-darwin flake configuration managing five hosts across Linux and macOS, built on flake-parts and easy-hosts.

## Key Commands
```bash
# List all workflows (the default recipe)
just

# Format all files (nixfmt, shfmt, stylua, deadnix, statix, keep-sorted, just)
just fmt

# Evaluate flake without building (catches syntax/type errors)
just check

# Rebuild and switch the current system
just rebuild

# Commit all repo changes with a standardized message
just commit

# Format, check (warn), rebuild, and commit
just switch

# Pull, update the lock, check (require), then switch
just update

# Garbage-collect and optimise the store, keeping N generations (default 3)
just clean

# Build a specific host without switching
nix build .#nixosConfigurations.home-desktop.config.system.build.toplevel
nix build .#nixosConfigurations.home-media.config.system.build.toplevel
nix build .#darwinConfigurations.Rohans-MacBook.config.system.build.toplevel
```


## Architecture

### Flake Entry Point

`flake.nix` delegates configuration to flake-parts via `inputs.import-tree ./modules` and imports the wrapper framework separately. Automatically discovered files under `modules/` are flake-parts modules; underscore-prefixed directories are skipped and imported explicitly. Features are exposed as aspects through `flake.modules.<class>.<name>`. Discovery registers definitions; host and umbrella imports activate them.

The flake modules in `modules/flake/` define:
- `args.nix` — overlays and system configuration
- `formatter.nix` — treefmt with nixfmt, deadnix, statix, shfmt, shellcheck, stylua, keep-sorted
- `modules.nix` — enables the `flake.modules.*` namespace
- `packages/` — reserved (empty); workflows live in the root `Justfile`

### Host Management (easy-hosts)

Hosts are defined in `modules/hosts.nix` with their class and architecture:

| Host | Class | Arch | Role |
|------|-------|------|------|
| **home-desktop** | nixos | x86_64 | Desktop (Niri/Noctalia, NVIDIA) |
| **home-media** | nixos | x86_64 | Media server (arr stack, Jellyfin) — no home-manager |
| **home-nas** | nixos | x86_64 | ZFS storage, SMB/NFS, Paperless — no home-manager |
| **home-controller** | nixos | x86_64 | Home Assistant VM, identity, monitoring — no home-manager |
| **Rohans-MacBook** | darwin | aarch64 | MacBook (Paneru, Homebrew) |

`perClass` applies `self.modules.<class>.default`. Each host dir (`hosts/{name}/`) has `default.nix` plus `hardware-configuration.nix` and `user.nix` where applicable; everything else is opted into by importing aspects (e.g. `self.modules.nixos.graphical`, `self.modules.nixos.rdatar`).

### Module Hierarchy

```
modules/
  meta.nix          — flake.meta.defaults (default programs)
  topology.nix      — typed flake.meta.topology (shared host addresses, gateway, identity, media paths)
  infrastructure/   — cross-host relationships: NAS/media storage and controller/media monitoring
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

Features are organized as aspects under `flake.modules.<class>.<name>`. Hosts opt in by importing the relevant aspect (e.g. `self.modules.nixos.graphical`). Feature enablement is **import-based**: there are no custom enable flags — importing an aspect enables it. Custom metadata options are flake-level: `flake.meta.defaults` (`modules/meta.nix`) and `flake.meta.topology` (`modules/topology.nix`). Aspect files capture these through the outer flake-parts `config`; plain host modules access `self.meta.topology`.

Keep shared addresses and identity naming in the topology inventory. `modules/infrastructure/media-storage.nix` owns the media export/mount paths and defines both `nas-nfs` and `media-storage`; hosts import their respective sides explicitly. Inventory data does not enable services. Keep interface names, prefix lengths, and hardware policy host-local; never read another host's evaluated `nixosConfigurations` to obtain shared facts.

`modules/infrastructure/media-monitoring.nix` owns the private direct-probe list and defines `media-probes` (imported by `gatus`) and `media-probe-access` (imported by `media-ingress`). Probe targets and their firewall ports come from that one list. Public auth checks remain separate; preserve endpoint ordering when changing the Gatus composition.

The NixOS `graphical` umbrella does not choose a session: `home-desktop` explicitly imports `niri-desktop`. Keep scaling and workstation DRM workarounds host-local, and NVIDIA environment settings in `nvidia`. NAS host ID/pool/boot policy lives in `hosts/home-nas/default.nix`; the controller imports generic `libvirt` plus its plain `haos.nix` module for guest-specific USB, shutdown, Cockpit, and domain policy.

### Home Manager Integration

Home Manager is a graphical-host concern: `flake.modules.<class>.home-manager` (in `modules/home-manager.nix`) is imported by the `graphical` umbrella aspects, with `useGlobalPkgs = true` and `useUserPackages = true`. Server hosts have **no home-manager**. All hosts receive common wrapped tools (`modules/wrapped/`) through shared `base` aspects; `server` adds administrative tools, minimal Neovim, and wrapped direnv. Per-user configs live in `modules/home/_{username}/` (underscore-prefixed so import-tree skips them; the files inside are plain HM modules), exposed as `flake.modules.homeManager.{username}` by `modules/home/users.nix` and attached in each host's `user.nix` (`home-manager.users.<name>.imports`). The flake-parts definitions in `modules/home/_internal/` are explicitly registered by `modules/home/default.nix`, separately from its default aspect selection.

### Secrets

Managed with Ragenix. Encrypted `.age` files in `secrets/`. Never commit plaintext secrets.

## Conventions

- **Formatter**: Always run `just fmt` before committing. The `just switch` command does this automatically.
- **keep-sorted**: Lists marked with `# keep-sorted start` / `# keep-sorted end` are auto-sorted by the formatter. Add new items anywhere in the block; they'll be sorted on format.
- **Module pattern**: Feature modules should define `flake.modules.<class>.<name>` aspects. OS/Home Manager `pkgs`, `config`, and `osConfig` belong inside the aspect value. The outer flake-parts `config` may be captured to read `flake.meta.defaults` or `flake.meta.topology`; it is not the OS configuration.
- **Conditional config**: Gate features by import, not flags — graphical-only settings belong in aspects imported by the `graphical` umbrellas. Use `_class` checks for NixOS vs Darwin differences when a single file defines both classes, and `pkgs.stdenv.hostPlatform` checks for platform differences inside Home Manager modules.
- **CI**: Pushes trigger `nix flake check` on Linux and macOS runners; all four NixOS host closures are built and published to the signed binary cache. Flake lock is auto-updated on a schedule (Tue/Thu) with auto-merge after checks pass.
