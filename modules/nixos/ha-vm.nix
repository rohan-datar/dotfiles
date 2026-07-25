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

      # udev rules give the dongles stable /dev symlinks; pass THOSE to the guest by device path.
      services.udev.extraRules = ''
        SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2357", SYMLINK+="btusb"
      '';
    };
}
