# Configuration Architecture

This document provides an in-depth explanation of how the Nix configuration in this repository is structured and how the various components interact.

## Flake Structure

The `flake.nix` file is the entry point for the configuration. It uses the `flake-parts` library to create a modular flake structure. The key components are:

- **Inputs**: External dependencies like nixpkgs, home-manager, nix-darwin, etc.
- **Outputs**: The configurations generated for different systems
- **Imports**: References to other modules that contribute to the flake

## Host Management with easy-hosts

The configuration uses the `easy-hosts` flake to simplify host management. In `hosts/default.nix`, hosts are defined with their class (nixos or darwin) and architecture:

```nix
config.easy-hosts = {
  perClass = class: {
      modules = [
        "${self}/modules/${class}/default.nix"
      ];
    };

  hosts = {
    home-desktop = { class = "nixos"; };
    macbook = {
      arch = "aarch64";
      class = "darwin";
    };
  };
};
```

This approach allows for:
- Automatic application of class-specific modules
- Clear distinction between NixOS and Darwin systems
- Easy addition of new hosts

## Module System

The configuration uses a hierarchical module system:

### Global Modules (`modules/global`)

These modules define options and configurations shared across all systems, like the `olympus` namespace and global packages.

### Class-specific Modules

- **NixOS Modules** (`modules/nixos`): Settings for Linux systems
- **Darwin Modules** (`modules/darwin`): Settings for macOS systems
- **Home Modules** (`modules/home`): Settings for user environments

### Shared Modules (`modules/shared`)

These contain settings that are shared across all systems regardless of class, like font configurations, documentation, and Nix settings.

## The olympus Namespace

Instead of polluting the global namespace, this configuration uses a custom `olympus` namespace for organizing options:

```nix
options.olympus.aspects = {
  graphical.enable = mkEnableOption "Enable graphical environment aspects";
  server.enable = mkEnableOption "Enable server environment aspects";
};
```

This pattern allows for:
- Clear organization of custom options
- Aspect-based configuration toggling
- Consistent naming conventions

## Home Manager Integration

Home Manager is integrated to manage user environments. The configuration in `home/default.nix` sets up:

- User-specific configurations based on system users
- Shared modules for all users
- Special arguments passed to user configurations

```nix
home-manager = {
  verbose = true;
  useUserPackages = true;
  useGlobalPkgs = true;
  backupFileExtension = "bak";

  users = genAttrs config.olympus.system.users (name: {
    imports = [ ./${name} ];
  });

  sharedModules = [
    (self + /modules/home/default.nix)
    inputs.nix-index-database.homeModules.nix-index
  ];
};
```

## User Configurations

User configurations are stored in the `home/` directory and are structured as:

- `home/rdatar/`: Linux user configuration
  - `default.nix`: Entry point with imports and basic user settings
  - `packages.nix`: User-specific packages
  - `programs/`: Program-specific configurations
  - `ui/`: UI-related configurations (for Hyprland, etc.)

- `home/rohandatar/`: macOS user configuration
  - Similar structure adapted for macOS

## System Aspects

The configuration uses an "aspects" system to toggle features:

```nix
olympus.aspects.graphical.enable = true;
```

This enables all graphical environment-related settings across the system, which might include:

- Display servers
- Window managers
- UI applications
- Fonts and themes

## Secret Management

Secrets are managed using [Agenix](https://github.com/ryantm/agenix) and stored in the `secrets/` directory. Secrets include:

- API keys
- Passwords
- Configuration files with sensitive data

## UI Configuration

For graphical systems (where `olympus.aspects.graphical.enable = true`), the configuration includes:

- **Hyprland** window manager (for Linux)
- **Wallpaper** settings
- **Lock screen** configuration
- **Notifications** setup
- **Search** functionality
- **Panel/Bar** configuration

## Package Management

Packages are defined at multiple levels:

- **Global packages** in `modules/global/packages.nix`
- **System-specific packages** in host configurations
- **User-specific packages** in user configurations

## Homebrew Integration (macOS)

For macOS systems, Homebrew is integrated to manage packages that aren't available in nixpkgs:

```nix
homebrew = {
  enable = true;
  brews = [
    "openjdk@21"
    "xcode-build-server"
  ];

  casks = [
    "omnidisksweeper"
    "beeper"
  ];

  masApps = {
    "Xcode" = 497799835;
  };
};
```

This allows for a hybrid approach to package management on macOS.

## Hardware Optimization

The configuration includes hardware-specific optimizations:

- CPU-specific settings (Intel)
- GPU-specific settings (NVIDIA/Intel)
- Bluetooth and sound configurations
- Hardware acceleration


## Key Files and Their Purposes

- `flake.nix`: Main entry point for the flake
- `hosts/default.nix`: Host management configuration
- `modules/flake/args.nix`: Flake arguments and system settings
- `modules/global/aspects.nix`: Aspect system definition
- `modules/home/default.nix`: Home Manager module imports
- `home/*/default.nix`: User-specific configurations
