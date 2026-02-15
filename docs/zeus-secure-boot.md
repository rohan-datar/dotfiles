# Enabling Secure Boot on Zeus (MSI Motherboard)

This guide walks through enabling UEFI Secure Boot on Zeus using
**Limine's built-in Secure Boot support**. Limine uses `sbctl` to sign
its EFI binary and manages the chain of trust natively.

No external flake inputs are needed — everything is in nixpkgs.

**Keep a NixOS live USB handy throughout.** If anything goes wrong, you can
boot from the USB and revert.

---

## Phase 1: Switch from GRUB to Limine

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
boot.loader.limine = {
  enable = true;
  efiSupport = true;
  maxGenerations = 20;
  extraEntries = ''
    /Windows
      protocol: chainload
      path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
  '';
};
```

Notes:
- `useOSProber` is replaced by an explicit `extraEntries` chainload entry
  for Windows. The `extraEntries` option is a raw string in Limine config
  format (not a Nix attrset).
- `efiInstallAsRemovable` is dropped. It defaults based on
  `!boot.loader.efi.canTouchEfiVariables`. If the system can't find the
  boot entry after switching, set `boot.loader.limine.efiInstallAsRemovable = true`.
- `configurationLimit` maps to `maxGenerations`.

### 1.2 Clean up the ESP

Your ESP (`/boot`) is currently full at 511MB. Before switching, free up
space:

```bash
# Check what's using space
sudo du -h --max-depth=2 /boot/ | sort -hr | head -20

# Remove old GRUB files (no longer needed after switching)
sudo rm -rf /boot/grub

# Verify free space
df -h /boot
```

### 1.3 Rebuild and reboot

```bash
sudo nixos-rebuild switch
reboot
```

Verify:
- Limine boot menu appears
- NixOS boots successfully
- Windows appears in the boot menu

---

## Phase 2: Set up Secure Boot keys

### 2.1 Add sbctl to system packages

In `hosts/zeus/default.nix`, add:

```nix
environment.systemPackages = [ pkgs.sbctl ];
```

Rebuild so `sbctl` is available:

```bash
sudo nixos-rebuild switch
```

### 2.2 Create Secure Boot signing keys

```bash
sudo sbctl create-keys
```

This creates keys in `/var/lib/sbctl/` with root-only permissions.

### 2.3 Put MSI BIOS into Setup Mode

1. Reboot and press **Delete** during POST to enter MSI BIOS (Click BIOS)
2. Navigate to **Settings > Security > Secure Boot**
3. Set **Secure Boot Mode** to **Custom** (this enables key management)
4. Enter **Key Management**
5. Select **Delete All Secure Boot Keys** or **Reset to Setup Mode**
   (exact wording varies by BIOS version)

> **Warning**: If you see separate options for "Reset to Setup Mode" vs
> "Clear All Keys", prefer "Reset to Setup Mode". Clearing all keys also
> removes the dbx (revocation database), which is a security concern.

6. Press **F10** to save and exit

### 2.4 Enroll your keys

Boot back into NixOS and run:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

Flags:
- `--microsoft` is **essential** — it includes Microsoft's OEM certificates
  needed for hardware OptionROMs (GPU, network card, etc.). Without it, you
  may lose display output on boot. Also required for Windows dual-boot.
- `--firmware-builtin` preserves any OEM certificates from your MSI firmware.

---

## Phase 3: Enable Limine Secure Boot

### 3.1 Enable Secure Boot in Limine config

In `hosts/zeus/hardware-configuration.nix`, add to the Limine block:

```nix
boot.loader.limine = {
  enable = true;
  efiSupport = true;
  maxGenerations = 20;
  secureBoot.enable = true;    # <-- add this
  extraEntries = ''
    /Windows
      protocol: chainload
      path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
  '';
};
```

When `secureBoot.enable = true`, Limine automatically enforces:
- `enrollConfig = true` (config is enrolled into the trust chain)
- `validateChecksums = true` (file checksums validated before boot)
- `panicOnChecksumMismatch = true` (checksum failure is fatal)

### 3.2 Rebuild

```bash
sudo nixos-rebuild switch
```

This signs the Limine EFI binary with your `sbctl` keys.

### 3.3 Enable Secure Boot in BIOS

1. Reboot into BIOS (press **Delete**)
2. Go to **Settings > Security > Secure Boot**
3. **Enable** Secure Boot
4. Press **F10** to save and exit

### 3.4 Verify

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

### Can't boot after switching to Limine (Phase 1)
1. Boot from NixOS live USB
2. Mount your partitions (`mount /dev/... /mnt && mount /dev/... /mnt/boot`)
3. Revert `hardware-configuration.nix` back to GRUB
4. Run `nixos-rebuild switch --install-bootloader --flake /mnt/path/to/flake#zeus`

### Can't boot after enabling Secure Boot (Phase 3)
1. Enter BIOS (press **Delete**)
2. Disable Secure Boot in **Settings > Security > Secure Boot**
3. Boot normally and troubleshoot

---

## Summary of all file changes

### `hosts/zeus/hardware-configuration.nix` — bootloader config
```nix
boot.loader.limine = {
  enable = true;
  efiSupport = true;
  maxGenerations = 20;
  secureBoot.enable = true;
  extraEntries = ''
    /Windows
      protocol: chainload
      path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
  '';
};
```

### `hosts/zeus/default.nix` — sbctl package
```nix
environment.systemPackages = [ pkgs.sbctl ];
```
