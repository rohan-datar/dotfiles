_: {
  flake.modules.nixos.ha-vm =
    { pkgs, ... }:
    {
      # OVMF (UEFI firmware for the HAOS guest) ships with QEMU by default;
      # the old qemu.ovmf option was removed from nixpkgs.
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true; # optional GUI over SSH -X / remote

      environment.systemPackages = [
        pkgs.virt-manager
        pkgs.virtiofsd
      ];

      # udev rules give the dongles stable /dev symlinks; pass THOSE to the guest by device path.
      services.udev.extraRules = ''
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2357", SYMLINK+="btusb"
      '';
    };
}
