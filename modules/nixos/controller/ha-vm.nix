_: {
  flake.modules.nixos.ha-vm =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        dbus.enable = true;
      };
      # The bridge's service user must pass libvirtd's polkit check
      # (org.libvirt.unix.manage is granted to the libvirtd group)
      users.users.libvirtdbus.extraGroups = [ "libvirtd" ];
      programs.virt-manager.enable = true; # optional GUI over SSH -X / remote

      # Web UI for the HAOS guest: VM state + console in the browser,
      # nicer than virt-manager over X forwarding when the VM won't boot.
      services.cockpit = {
        enable = true;
        port = 9090;
        plugins = [ pkgs.cockpit-machines ];

        allowed-origins = [
          "https://10.10.1.13:9090"
          "wss://10.10.1.13:9090"
          "https://controller.rdatar.com"
          "wss://controller.rdatar.com"
        ];
        settings.WebService = {
          # Caddy terminates TLS and proxies plain http; without this cockpit
          # redirects http→https and Firefox loops. LAN-only exposure.
          AllowUnencrypted = true;
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
        };
      };
      networking.firewall.interfaces.br0.allowedTCPPorts = [ 9090 ];

      environment.systemPackages = [
        pkgs.virt-manager
        pkgs.virtiofsd
      ];

      # Both dongles go to the guest by USB passthrough, so the host must never bind them:
      # libvirt unbinds at VM start, but a USB reset re-probes and the host wins the race,
      # leaving the guest with a dead handle. Host runs no Bluetooth stack of its own.
      boot.blacklistedKernelModules = [
        "cp210x"
        "btusb"
      ];

      # Vestigial: the BT dongle is also passed through as a USB device, so this symlink is
      # unused. Harmless (a usb-subsystem SYMLINK binds no driver), kept only as a handle for
      # host-side debugging.
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2357", SYMLINK+="btusb"
      '';
    };
}
