_: {
  flake.modules.nixos.ha-vm =
    { pkgs, ... }:
    let
      haosDomain = ../../../hosts/home-controller/haos.xml;
    in
    {
      virtualisation.libvirtd = {
        enable = true;
        dbus.enable = true;
        # NixOS defaults this to "suspend", which managedsaves the guest at host shutdown and
        # restores it from that RAM image at boot. Restoring is incompatible with USB
        # passthrough: QEMU re-creates the usb-host devices, but a resumed guest never
        # re-enumerates its USB bus, so nothing claims them and both radios come back dead.
        # Verified minimal: `virsh managedsave haos && virsh start haos` breaks them on a
        # settled host with no reboot at all — the host-side interfaces go from "usbfs" to
        # unclaimed. libvirt 12.4.0 additionally segfaults in qemuDomainRestoreInternal when
        # the restore happens via autostart at daemon start (not via virsh start).
        # Shut the guest down properly instead; a cold boot re-enumerates, and costs ~40s of
        # extra host shutdown time.
        onShutdown = "shutdown";
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

      # Both dongles go to the guest by USB passthrough, so the host must never bind them.
      # libvirt unbinds the host driver when the VM starts, but that unbind does not survive
      # `nixos-rebuild switch`: switch-to-configuration restarts systemd-udevd, udev re-probes
      # every device, and cp210x/btusb rebind — silently stealing both dongles out from under
      # the running guest. That is what killed Zigbee + Bluetooth on 2026-07-25; the VM had
      # been fine for five days until the day's first rebuild. Blacklisting is what makes the
      # unbind permanent. The host runs no Bluetooth stack of its own, so it loses nothing.
      #
      # The second, separate failure mode here was libvirt-guests restoring the VM from a saved
      # image at boot rather than cold-booting it; see virtualisation.libvirtd.onShutdown
      # above. Symptom was identical to the driver race — dongles dead, guest never claiming
      # them (host interfaces read empty rather than "usbfs") — which made the two easy to
      # confuse. Diagnostic that tells them apart: if the host drivers are absent AND the guest
      # still doesn't claim the devices, it was a restore, not a rebind.
      #
      # The domain uses qemu-xhci rather than libvirt's default ich9 EHCI+UHCI companion set.
      # That was changed while chasing the restore bug and is retained as the better controller
      # for passthrough, but it was never the fix for either failure.
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

      # libvirt keeps domain definitions in its own state dir, so a hand-run `virsh edit` is
      # invisible to this flake and survives no reinstall. This re-defines the guest from the
      # checked-in XML on every activation, making that file the source of truth.
      #
      # `virsh define` against a *running* domain rewrites only the persisted config and never
      # disturbs the live guest — so edits to the XML land on the VM's next restart rather than
      # bouncing Home Assistant underneath you on every rebuild. That's deliberate; restarting
      # the guest is left a manual step.
      systemd.services.haos-domain = {
        description = "Define the HAOS libvirt domain from the flake";
        after = [ "libvirtd.service" ];
        requires = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        # RemainAfterExit would otherwise skip re-running when only the XML changed.
        restartTriggers = [ haosDomain ];
        path = [ pkgs.libvirt ];
        environment.LIBVIRT_DEFAULT_URI = "qemu:///system";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          virsh define ${haosDomain}
          virsh autostart haos
        '';
      };
    };
}
