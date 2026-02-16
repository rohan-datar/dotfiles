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
nix build .#nixosConfigurations.zeus.config.system.build.toplevel
nix build .#darwinConfigurations.apollo.config.system.build.toplevel
```

## Architecture

### Flake Entry Point

`flake.nix` delegates everything to flake-parts via `imports = [ ./modules/flake ]`. The flake modules in `modules/flake/` define:
- `args.nix` — overlays and system configuration
- `formatter.nix` — treefmt with nixfmt, deadnix, statix, shfmt, shellcheck, stylua, keep-sorted
- `packages/` — the `nx` helper script

### Host Management (easy-hosts)

Hosts are defined in `hosts/default.nix` with class and tags:

| Host | Class | Arch | Tags | Role |
|------|-------|------|------|------|
| **zeus** | nixos | x86_64 | full | Desktop (Hyprland/Niri, NVIDIA) |
| **dionysus** | nixos | x86_64 | minimal | Media server (arr stack, Jellyfin) |
| **apollo** | darwin | aarch64 | full | MacBook (Aerospace, Homebrew) |

`perClass` auto-loads `modules/{nixos,darwin}/default.nix`. `perTag` sets `neovimPkg` specialArg ("full" or "minimal"). Each host dir (`hosts/{name}/`) has `default.nix`, `hardware-configuration.nix`, and `user.nix`.

### Module Hierarchy

```
modules/
  global/    — olympus option declarations (aspects, packages)
  shared/    — applied to ALL hosts (user creation, fonts, nix settings, home-manager setup)
  nixos/     — NixOS-only (hardware, graphical, system, services)
  darwin/    — macOS-only (system prefs, homebrew, nix settings)
  home/      — Home Manager modules (programs, env, XDG)
  flake/     — flake-parts modules (formatter, packages, args)
```

### The `olympus` Namespace

All custom options live under `olympus.*` to avoid polluting the global namespace:
- `olympus.aspects.{graphical,server}.enable` — feature toggles that gate entire feature sets
- `olympus.system.{users,cpu,gpu,sound,bluetooth,emulation}` — hardware/system options
- `olympus.services.{arr,homepage}` — service toggles
- `olympus.programs.defaults.{shell,terminal,editor,browser,launcher,screenLocker}` — default programs

### Home Manager Integration

Configured in `modules/shared/default.nix` with `useGlobalPkgs = true` and `useUserPackages = true`. Per-user configs live in `home/{username}/`. Shared home modules from `modules/home/` are applied to all users.

### Secrets

Managed with Agenix. Encrypted `.age` files in `secrets/`. Never commit plaintext secrets.

## Conventions

- **Formatter**: Always run `nix fmt` before committing. The `nx switch` command does this automatically.
- **keep-sorted**: Lists marked with `# keep-sorted start` / `# keep-sorted end` are auto-sorted by the formatter. Add new items anywhere in the block; they'll be sorted on format.
- **Module pattern**: New modules should define options under the `olympus` namespace and use `mkIf` to gate configuration on the relevant aspect/option.
- **Conditional config**: Use `lib.mkIf config.olympus.aspects.graphical.enable` to gate graphical-only settings. Use `_class` checks for NixOS vs Darwin differences.
- **CI**: Pushes trigger `nix flake check --all-systems` on both Linux and macOS runners. Flake lock is auto-updated on a schedule (Tue/Thu) with auto-merge after checks pass.
