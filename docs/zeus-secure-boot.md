# Enabling Secure Boot on Zeus (MSI PRO B760-VC WiFi)

This guide walks through enabling UEFI Secure Boot on Zeus using
**Limine's built-in Secure Boot support**. Limine uses `sbctl` to sign
its EFI binary and manages the chain of trust natively.

No external flake inputs are needed — everything is in nixpkgs.

**Keep a NixOS live USB handy throughout.** If anything goes wrong, you can
boot from the USB and revert.

---

## MSI-Specific Notes

MSI B760 boards have two known firmware issues that affect Secure Boot:

1. **"Provision Factory Default keys"** is enabled by default. This causes
   the firmware to silently re-enroll factory keys on every reboot, preventing
   you from entering Setup Mode. You must disable this setting before
   deleting Secure Boot variables.

2. **FQ0001: Insecure execution policy.** The firmware defaults to "Always
   Execute" on Secure Boot policy violations, making Secure Boot useless
   even when enabled. You must change the Image Execution Policy to
   "Deny Execute" for Secure Boot to actually enforce signature checks.

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
      protocol: efi_chainload
      path: fslabel(SYSTEM):/EFI/Microsoft/Boot/bootmgfw.efi
  '';
};
```

Notes:
- `useOSProber` is replaced by an explicit `extraEntries` chainload entry
  for Windows. The `extraEntries` option is a raw string in Limine config
  format (not a Nix attrset).
- Windows' EFI files are on a separate ESP (labeled `SYSTEM`). The
  `fslabel(SYSTEM):` prefix tells Limine to look on that partition.
- `efiInstallAsRemovable` is dropped. It defaults based on
  `!boot.loader.efi.canTouchEfiVariables`. If the system can't find the
  boot entry after switching, set `boot.loader.limine.efiInstallAsRemovable = true`.
- `configurationLimit` maps to `maxGenerations`.

### 1.2 Clean up the ESP

The ESP (`/boot`) may be full. Before switching, free up space:

```bash
# Check what's using space
sudo du -h --max-depth=2 /boot/ | sort -hr | head -20

# Remove old GRUB files (no longer needed after switching)
sudo rm -rf /boot/grub

# Remove leftover systemd-boot files if present
sudo rm -rf /boot/EFI/systemd /boot/EFI/Linux /boot/EFI/NixOS-boot
sudo rm -f /boot/loader/loader.conf

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
- Windows entry works (boots into Windows)

---

## Phase 2: Set up Secure Boot keys

### 2.1 Add sbctl to system packages

In `hosts/zeus/default.nix`, add `sbctl` to packages. Then rebuild:

```bash
sudo nixos-rebuild switch
```

### 2.2 Create Secure Boot signing keys

```bash
sudo sbctl create-keys
```

This creates keys in `/var/lib/sbctl/` with root-only permissions.

### 2.3 Fix MSI firmware security settings

Reboot and press **Delete** during POST to enter MSI BIOS (Click BIOS).

#### Fix Image Execution Policy (FQ0001)

1. Navigate to **Settings > Security > Secure Boot**
2. Set **Secure Boot Mode** to **Custom**
3. Find **Image Execution Policy**
4. Change **Removable Media** and **Fixed Media** from "Always Execute" to
   **"Deny Execute"**

> **Warning**: Do NOT set these to "Always Deny" — that blocks all binaries
> including signed ones and can make the system unbootable.

#### Disable factory key auto-re-enrollment

1. Still in **Secure Boot** or **Key Management**, find
   **"Provision Factory Default keys"** (may also be called "Factory Default
   Key Provisioning")
2. Set it to **Disabled**

> This setting is easy to miss. It may be a small toggle within the Key
> Management submenu or one level up in the Secure Boot settings.

### 2.4 Put firmware into Setup Mode

1. Still in **Key Management**, select **"Delete all Secure Boot variables"**
2. Confirm the deletion
3. Press **F10** to save and exit

> **Important**: Steps 2.3 and 2.4 must be done in the same BIOS session.
> If you save and reboot between disabling "Provision Factory Default keys"
> and deleting the variables, the firmware may re-enable the setting.

### 2.5 Verify Setup Mode

Boot into NixOS and run:

```bash
sudo sbctl status
```

You should see:

```
Setup Mode:     ✓ Enabled
Secure Boot:    ✗ Disabled
```

If Setup Mode still shows Disabled, see the Troubleshooting section below.

### 2.6 Enroll your keys

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

Flags:
- `--microsoft` is **essential** — includes Microsoft's OEM certificates
  needed for hardware OptionROMs (GPU, network card, etc.). Without it, you
  may lose display output on boot. Also required for Windows dual-boot.
- `--firmware-builtin` preserves any OEM certificates from your MSI firmware.

---

## Phase 3: Enable Limine Secure Boot

### 3.1 Enable Secure Boot in Limine config

In `hosts/zeus/hardware-configuration.nix`, add `secureBoot.enable = true`
to the Limine block:

```nix
boot.loader.limine = {
  enable = true;
  efiSupport = true;
  maxGenerations = 20;
  secureBoot.enable = true;
  extraEntries = ''
    /Windows
      protocol: efi_chainload
      path: fslabel(SYSTEM):/EFI/Microsoft/Boot/bootmgfw.efi
  '';
};
```

When `secureBoot.enable = true`, Limine automatically enforces:
- `enrollConfig = true` (config enrolled into the trust chain)
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

## Troubleshooting

### Setup Mode won't enable after deleting variables

If `sbctl status` still shows "Setup Mode: Disabled" after following the
steps above:

**Option A: Delete the Platform Key individually**

In the BIOS Key Management (Custom mode), look for individual key variables
(PK, KEK, db, dbx). Delete **PK** specifically. A system enters Setup Mode
when the Platform Key is removed — the other keys can remain.

**Option B: Delete PK from Linux**

```bash
# You may need efitools: nix-shell -p efitools
sudo chattr -i /sys/firmware/efi/efivars/PK-8be4df61-93ca-11d2-aa0d-00e098032b8c
sudo efi-updatevar -d 0 PK
```

This may fail with "Operation not permitted" depending on firmware
protections. If so, the BIOS method is the only path.

**Option C: Export keys and enroll through BIOS**

```bash
sudo sbctl enroll-keys --export auth
sudo cp *.auth /boot/
```

Then in the BIOS Key Management, enroll the `.auth` files manually in this
order: **db first, then KEK, then PK last**.

### FQ0001 quirk still reported after fixing execution policy

This is cosmetic. `sbctl` detects the quirk based on firmware identity, not
the current policy setting. As long as you changed the execution policy to
"Deny Execute", Secure Boot will enforce signature checks correctly.

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
      protocol: efi_chainload
      path: fslabel(SYSTEM):/EFI/Microsoft/Boot/bootmgfw.efi
  '';
};
```

### `hosts/zeus/default.nix` — sbctl package
```nix
environment.systemPackages = [ pkgs.sbctl ];
```
