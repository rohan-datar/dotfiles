_: {
  flake.modules.nixos.libvirt =
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

      environment.systemPackages = [
        pkgs.virt-manager
        pkgs.virtiofsd
      ];
    };
}
