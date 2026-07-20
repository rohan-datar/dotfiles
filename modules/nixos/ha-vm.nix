_: {
  flake.modules.nixos.ha-vm =
    { pkgs, ... }:
    {
      # OVMF (UEFI firmware for the HAOS guest) ships with QEMU by default;
      # the old qemu.ovmf option was removed from nixpkgs.
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true; # optional GUI over SSH -X / remote

      # Web UI for the HAOS guest: VM state + console in the browser,
      # nicer than virt-manager over X forwarding when the VM won't boot.
      services.cockpit = {
        enable = true;
        port = 9090;
        plugins = [ pkgs.cockpit-machines ];
      };
      networking.firewall.interfaces.br0.allowedTCPPorts = [ 9090 ];

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
