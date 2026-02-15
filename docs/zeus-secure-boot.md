# Enabling Secure Boot on Zeus (MSI Motherboard)

This guide walks through enabling UEFI Secure Boot on Zeus using
**lanzaboote** — the standard Secure Boot tool for NixOS. Lanzaboote works
with **systemd-boot**, so we'll switch from GRUB as part of the process.

**Keep a NixOS live USB handy throughout.** If anything goes wrong, you can
boot from the USB and revert.

---

## Phase 1: Switch from GRUB to systemd-boot

Lanzaboote requires systemd-boot. We switch to it first and verify it works
before adding Secure Boot.

### 1.1 Update the bootloader config

In `hosts/zeus/hardware-configuration.nix`, replace the GRUB block:

```nix
# Remove this:
boot.loader.grub = {
  enable = true;
  devices = [ "nodev" ];
  efiSupport = true;
  useOSProber = true;
  configurationLimit = 20;
  efiInstallAsRemovable = true;
};
```

```nix
# Replace with:
boot.loader.systemd-boot = {
  enable = true;
  configurationLimit = 20;
};
boot.loader.efi.canTouchEfiVariables = true;
```

Notes:
- `useOSProber` is not needed — systemd-boot auto-detects Windows EFI
  entries on the ESP.
- `efiInstallAsRemovable` is dropped. With `canTouchEfiVariables = true`,
  systemd-boot creates a proper EFI boot entry. If the system can't find the
  entry after switching, add `boot.loader.efi.efiSysMountPoint = "/boot";`
  or set `efiInstallAsRemovable = true` on systemd-boot's grub-compat option.

### 1.2 Rebuild and reboot

```bash
sudo nixos-rebuild switch
reboot
```

Verify:
- systemd-boot menu appears
- NixOS boots successfully
- Windows appears in the boot menu (if dual-booting)

Run `bootctl status` to confirm systemd-boot is active.

---

## Phase 2: Add lanzaboote

### 2.1 Add the flake input

In `flake.nix`, add to the `inputs` block:

```nix
lanzaboote = {
  url = "github:nix-community/lanzaboote/v1.0.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then update the lock file:

```bash
nix flake update lanzaboote
```

### 2.2 Import the lanzaboote NixOS module

In `modules/nixos/extras.nix`, add the lanzaboote module import:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.niri.nixosModules.niri
    inputs.lanzaboote.nixosModules.lanzaboote  # <-- add this
  ];
}
```

### 2.3 Configure lanzaboote on Zeus

In `hosts/zeus/hardware-configuration.nix`, update the bootloader section
to disable systemd-boot's installer (lanzaboote replaces it) and enable
lanzaboote:

```nix
# Bootloader.
boot.loader.systemd-boot.enable = lib.mkForce false;
boot.loader.efi.canTouchEfiVariables = true;

boot.lanzaboote = {
  enable = true;
  pkiBundle = "/var/lib/sbctl";
};
```

Also add `sbctl` to system packages. This can go in `hosts/zeus/default.nix`
or in `hardware-configuration.nix`:

```nix
environment.systemPackages = [ pkgs.sbctl ];
```

### 2.4 Create Secure Boot signing keys

```bash
sudo sbctl create-keys
```

This creates keys in `/var/lib/sbctl/` with root-only permissions.

### 2.5 Rebuild

```bash
sudo nixos-rebuild switch
```

### 2.6 Verify signatures

```bash
sudo sbctl verify
```

Expected output — most files show "is signed":

```
Verifying file database and EFI images in /boot...
  /boot/EFI/BOOT/BOOTX64.EFI is signed
  /boot/EFI/Linux/nixos-generation-XXX.efi is signed
  /boot/EFI/systemd/systemd-bootx64.efi is signed
  /boot/EFI/nixos/XXXX-linux-X.X.X-bzImage.efi is not signed
```

The unsigned `bzImage.efi` files are **normal** — lanzaboote verifies these
at boot time via embedded cryptographic hashes, not UEFI signatures.

---

## Phase 3: Configure MSI BIOS for Secure Boot

### 3.1 Enter BIOS

Reboot and press **Delete** during POST to enter MSI BIOS (Click BIOS).

### 3.2 Put firmware in Setup Mode

1. Navigate to **Settings > Security > Secure Boot**
2. Set **Secure Boot Mode** to **Custom** (this enables key management)
3. Enter **Key Management**
4. Select **Delete All Secure Boot Keys** or **Reset to Setup Mode**
   (exact wording varies by BIOS version)

> **Warning**: If you see separate options for "Reset to Setup Mode" vs
> "Clear All Keys", prefer "Reset to Setup Mode". Clearing all keys also
> removes the dbx (revocation database), which is a security concern.

5. Press **F10** to save and exit

### 3.3 Enroll your keys

Boot back into NixOS and run:

```bash
sudo sbctl enroll-keys --microsoft
```

The `--microsoft` flag is **essential** — it includes Microsoft's OEM
certificates needed for hardware OptionROMs (GPU, network card, etc.).
Without it, you may lose display output on boot.

If dual-booting Windows, the `--microsoft` flag also ensures Windows can
still boot.

### 3.4 Enable Secure Boot

1. Reboot into BIOS (press **Delete**)
2. Go to **Settings > Security > Secure Boot**
3. **Enable** Secure Boot
4. Press **F10** to save and exit

### 3.5 Verify

Boot into NixOS and run:

```bash
bootctl status
```

You should see:

```
Secure Boot: enabled (user)
```

---

## Post-Setup: Set a BIOS Password

Without a BIOS password, anyone with physical access can disable Secure Boot
in the firmware settings. In MSI BIOS:

1. Go to **Settings > Security**
2. Set **Administrator Password**

---

## Rollback

If something goes wrong at any phase:

### Can't boot after switching to systemd-boot (Phase 1)
1. Boot from NixOS live USB
2. Mount your partitions (`mount /dev/... /mnt && mount /dev/... /mnt/boot`)
3. Revert `hardware-configuration.nix` back to GRUB
4. Run `nixos-rebuild switch --install-bootloader --flake /mnt/path/to/flake#zeus`

### Can't boot after enabling lanzaboote (Phase 2)
1. Boot from NixOS live USB
2. Mount partitions
3. Revert to plain systemd-boot (remove `boot.lanzaboote` block, set
   `boot.loader.systemd-boot.enable = true`)
4. Rebuild with `--install-bootloader`

### Can't boot after enabling Secure Boot (Phase 3)
1. Enter BIOS (press **Delete**)
2. Disable Secure Boot in **Settings > Security > Secure Boot**
3. Boot normally and troubleshoot

---

## Summary of all file changes

### `flake.nix` — add input
```nix
lanzaboote = {
  url = "github:nix-community/lanzaboote/v1.0.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### `modules/nixos/extras.nix` — import module
```nix
inputs.lanzaboote.nixosModules.lanzaboote
```

### `hosts/zeus/hardware-configuration.nix` — bootloader config
```nix
boot.loader.systemd-boot.enable = lib.mkForce false;
boot.loader.efi.canTouchEfiVariables = true;

boot.lanzaboote = {
  enable = true;
  pkiBundle = "/var/lib/sbctl";
};
```

### `hosts/zeus/default.nix` — sbctl package
```nix
environment.systemPackages = [ pkgs.sbctl ];
```
