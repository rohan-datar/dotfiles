# Configuration Architecture

This document explains how the Nix configuration in this repository is structured. It follows the **dendritic pattern**: every file under `modules/` is a flake-parts module, and features are organized as aspects under `flake.modules.<class>.<name>`.

## Flake Structure

`flake.nix` is the entry point. It uses `flake-parts` plus the `import-tree` input to turn every file under `modules/` into a flake-parts module automatically:

```nix
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ inputs.import-tree.flakeModule ./modules ];
  };
}
```

The only explicit flake module imports are `modules/flake/`, which contains the pieces that cannot be discovered by `import-tree` (formatter, args, packages, and the `flake.modules` namespace plumbing).

## Host Management with easy-hosts

Hosts are defined in `modules/hosts.nix` using the `easy-hosts` flake:

```nix
config.easy-hosts = {
  hosts = {
    home-desktop = { class = "nixos"; };
    home-media = { class = "nixos"; };
    Rohans-MacBook = { arch = "aarch64"; class = "darwin"; };
  };
};
```

`easy-hosts` automatically applies the class-specific default aspect set. The host directory name is the real machine hostname (`networking.hostName`), so `nx switch` and `nixos-rebuild --flake .` resolve the correct configuration without any extra mapping.

## Module System

All modules live under `modules/` and are flake-parts modules.

### Flake-level plumbing (`modules/flake/`)

- `args.nix` — overlays, system configuration, and `perSystem` arguments
- `formatter.nix` — `treefmt` configuration
- `modules.nix` — enables the `flake.modules.*` namespace used by aspects
- `packages/nx/` — the `nx` helper script

### Class-agnostic options (`modules/meta.nix`)

The only custom option is at the flake level:

- `flake.meta.defaults.{terminal,editor,browser,launcher,screenLocker,...}` — flake-wide default programs

Home Manager aspect files read it by closing over the flake-parts `config` in
the outer function of the file. Everything else that used to be an option is
either import-based (feature aspects, per-user OS accounts in `modules/users/`)
or plain per-host config in `hosts/{name}/` (e.g. `FLAKE`/`NH_FLAKE` env vars).

### Class-specific aspects (`modules/nixos/` and `modules/darwin/`)

Each file under these directories contributes an aspect, e.g. `flake.modules.nixos.graphical` or `flake.modules.darwin.brew`. Hosts opt in by importing the aspects they need.

### Home Manager aspects (`modules/home/`)

Every file under `modules/home/_internal/` exposes a Home Manager aspect (`flake.modules.homeManager.<name>`). `modules/home/default.nix` also defines a default umbrella (`flake.modules.homeManager.default`) that imports the common aspects. User-specific configs live in `home/{username}/` and are attached in each host's `user.nix`.

### Shared modules (`modules/shared/`)

`modules/shared/default.nix` defines `flake.modules.generic.shared`, which `modules/hosts.nix` applies to every host; it dispatches to base, nixpkgs, and variables aspects based on `_class`. OS user accounts are aspects in `modules/users/` (`flake.modules.nixos.rdatar`, `flake.modules.darwin.rohandatar`) that hosts import explicitly.

## Home Manager Integration

Home Manager is a graphical-host concern. `modules/home-manager.nix` defines `flake.modules.{nixos,darwin}.home-manager`, which the `graphical` umbrella aspects import (`useGlobalPkgs = true`, `useUserPackages = true`, shared modules include `flake.modules.homeManager.default`). Server hosts have **no Home Manager**; they get self-contained wrapped tools from `modules/wrapped/` via the `server-base` aspect instead.

Per-user configs live in `modules/home/_{username}/` — the underscore prefix keeps import-tree from importing them, so the files inside are plain HM modules. `modules/home/users.nix` exposes each directory as an aspect (`flake.modules.homeManager.rdatar`, `flake.modules.homeManager.rohandatar`), and each graphical host's `user.nix` attaches it:

```nix
home-manager.users.rdatar = {
  imports = [
    self.modules.homeManager.rdatar
    self.modules.homeManager.neovim-full
  ];
};
```

## System Aspects

Features are enabled by importing aspects — there are no enable flags. For example, a graphical NixOS host imports `self.modules.nixos.graphical`, which in turn imports `self.modules.nixos.wayland`, `self.modules.nixos.hyprland`, `self.modules.nixos.fonts`, `self.modules.nixos.home-manager`, etc. Graphical-only behavior lives in aspects only the graphical umbrella imports.

## Secret Management

Secrets are managed with [Agenix](https://github.com/ryantm/agenix) and stored in `secrets/`. Never commit plaintext secrets.

## Package Management

Packages are defined directly in the aspect files that need them:

- System packages in `modules/nixos/*.nix` or `modules/darwin/*.nix`
- Home packages in `modules/home/_internal/*.nix`
- Host-specific packages in `hosts/{name}/default.nix`
- User-specific packages in `modules/home/_{username}/packages.nix`

## Homebrew Integration (macOS)

macOS hosts use the `brew` aspect (`self.modules.darwin.brew`) to manage Homebrew packages and casks.

## Hardware Optimization

Hardware-specific aspects are under `modules/nixos/`:

- `intel-cpu.nix` / `intel-gpu.nix` / `nvidia.nix`
- `bluetooth.nix` / `sound.nix`
- `emulation.nix` / `printing.nix`

## Key Files

- `flake.nix` — main entry point
- `modules/hosts.nix` — host definitions and `easy-hosts` wiring
- `modules/flake/` — flake-parts plumbing (formatter, args, packages)
- `modules/meta.nix` — flake-level options
- `modules/nixos/` — NixOS aspects
- `modules/darwin/` — macOS aspects
- `modules/home/` — Home Manager aspects, including per-user configs in `_{username}/`
- `modules/shared/` — class-agnostic shared modules
- `hosts/{hostname}/` — per-host configuration
- `secrets/` — agenix-encrypted secrets
