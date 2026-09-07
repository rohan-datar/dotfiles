# Configuration Architecture

This repository follows the **dendritic pattern**: discovered files under `modules/` are flake-parts modules, and features are organized as aspects under `flake.modules.<class>.<name>`. Underscore-prefixed directories are excluded from automatic discovery; their explicit imports are described below.

## Flake Structure

`flake.nix` uses `flake-parts` and `import-tree` to discover the flake-parts modules under `modules/`:

```nix
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [
      (inputs.import-tree ./modules)
      inputs.nix-wrapper-modules.flakeModules.wrappers
    ];
  };
}
```

`modules/flake/` is discovered by the same import tree as the feature modules. The wrapper framework is imported separately. Discovery registers aspect definitions; it does not enable their NixOS, Darwin, or Home Manager configuration. Host and umbrella imports select which aspects are active.

## Host Management with easy-hosts

Hosts are defined in `modules/hosts.nix` using the `easy-hosts` flake:

```nix
config.easy-hosts = {
  hosts = {
    home-desktop = { class = "nixos"; };
    home-media = { class = "nixos"; };
    home-nas = { class = "nixos"; };
    home-controller = { class = "nixos"; };
    Rohans-MacBook = { arch = "aarch64"; class = "darwin"; };
  };
};
```

`easy-hosts` automatically applies the class-specific default aspect set. The host directory name is the real machine hostname (`networking.hostName`), so `nx switch` and `nixos-rebuild --flake .` resolve the correct configuration without any extra mapping.

## Module System

Automatically discovered modules use the flake-parts module interface. Files in underscore-prefixed directories are imported explicitly and may use a different module interface.

### Flake-level plumbing (`modules/flake/`)

- `args.nix` — overlays, system configuration, and `perSystem` arguments
- `formatter.nix` — `treefmt` configuration
- `modules.nix` — enables the `flake.modules.*` namespace used by aspects
- `packages/nx/` — the `nx` helper script

### Flake-level metadata

- `modules/meta.nix` defines `flake.meta.defaults` — flake-wide default programs.
- `modules/topology.nix` defines the typed `flake.meta.topology` inventory — shared host addresses, gateway, identity provider naming, and media-storage paths.

Flake-parts aspects capture `config.flake.meta.topology` in an outer `let`, before an inner OS or Home Manager module introduces its own `config`. Plain host modules use `self.meta.topology`. No host evaluates another host's `nixosConfigurations` to discover these values.

### Cross-host relationships (`modules/infrastructure/`)

`media-storage.nix` owns the media export path and client mount point, and defines both sides of the NFS relationship:

- `flake.modules.nixos.nas-nfs` — NAS export and direct-link firewall access, explicitly imported by `home-nas`.
- `flake.modules.nixos.media-storage` — client mount, explicitly imported by `home-media`.

Both aspects consume the shared address inventory. The Arr media directory, dashboard disk widget, and NAS backup exclusion also consume the relationship's paths. Defining inventory data does not activate either aspect.

`media-monitoring.nix` owns one private list of direct media liveness probes and defines both sides of that relationship:

- `flake.modules.nixos.media-probes` — Gatus endpoints, imported by the controller's `gatus` aspect.
- `flake.modules.nixos.media-probe-access` — the matching controller-only firewall allowance, imported by the media host's `media-ingress` aspect.

The same probe ports generate both the backend URLs and firewall rule. Public authentication/certificate checks remain separate. Gatus uses `mkBefore` and `mkAfter` around the relationship's endpoints to preserve the existing display order; importing `media-probes` alone does not enable Gatus.

Keep repeated cross-host facts in the inventory and co-locate the two sides of a relationship where useful. Interface names, prefix lengths, hardware configuration, and application policy stay local. `home-assistant` is an external HAOS guest endpoint in the inventory, not another flake-managed host; its guest network configuration and Keycloak realm provisioning are not managed by the inventory.

### Class-specific aspects (`modules/nixos/` and `modules/darwin/`)

Each file under these directories contributes an aspect, e.g. `flake.modules.nixos.graphical` or `flake.modules.darwin.brew`. Hosts opt in by importing the aspects they need.

The NixOS `graphical` umbrella provides the common graphical environment without choosing a compositor or greeter. `home-desktop` explicitly imports `niri-desktop` for Niri, Noctalia, and the Noctalia greeter. Generic Wayland environment settings stay in `wayland`; NVIDIA settings stay in `nvidia`. Personal display scaling and the workstation DRM workaround stay in `hosts/home-desktop/default.nix`.

### Host-local hardware and guests

`hosts/home-nas/default.nix` owns its stable ZFS host ID, existing pool import, and bootloader/EFI choices. The `nas-zfs` aspect supplies ZFS support and scrub/trim maintenance, not those machine-specific values.

The controller imports the reusable `libvirt` aspect plus the plain host module `hosts/home-controller/haos.nix`. The latter owns the guest's USB passthrough policy, shutdown behavior, Cockpit access, and domain-definition service next to `haos.xml`. The XML remains the source of the persistent domain definition; a switch does not intentionally restart the running guest.

### Home Manager aspects (`modules/home/`)

Files under `modules/home/_internal/` expose Home Manager aspects (`flake.modules.homeManager.<name>`). Because import-tree skips this directory, `modules/home/default.nix` explicitly imports their definitions, then separately selects the common aspects for `flake.modules.homeManager.default`. Registration and activation are distinct: for example, `neovim-full` is registered there but selected by the graphical hosts' `user.nix` files.

### Shared modules (`modules/shared/`)

`modules/shared/default.nix` defines `flake.modules.generic.shared`, which `modules/hosts.nix` applies to every host; it dispatches to base, nixpkgs, and variables aspects based on `_class`. OS user accounts are aspects in `modules/users/` (`flake.modules.nixos.rdatar`, `flake.modules.darwin.rohandatar`) that hosts import explicitly.

## Home Manager Integration

Home Manager is a graphical-host concern. `modules/home-manager.nix` defines `flake.modules.{nixos,darwin}.home-manager`, which the `graphical` umbrellas import (`useGlobalPkgs = true`, `useUserPackages = true`, shared modules include `flake.modules.homeManager.default`). Server hosts have **no Home Manager**. All hosts receive common wrapped tools through the shared `base` aspects; the `server` aspect adds server administration tools, minimal Neovim, and wrapped direnv.

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

Features are enabled by importing aspects — there are no enable flags. For example, a graphical NixOS host imports `self.modules.nixos.graphical`, which in turn imports `self.modules.nixos.wayland`, `self.modules.nixos.fonts`, `self.modules.nixos.home-manager`, etc. Graphical-only behavior lives in aspects only the graphical umbrella imports.

## Secret Management

Secrets are managed with [Ragenix](https://github.com/yaxitech/ragenix) and stored in `secrets/`. Never commit plaintext secrets.

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
- `secrets/` — ragenix-encrypted secrets
