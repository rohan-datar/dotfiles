{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  boot = {
    # We enable Systemd in the initrd so we can use it to mount the root
    # filesystem this will remove Perl from the activation
    initrd.systemd.enable = true;
  };

  # Declarative user management
  services.userborn.enable = true;

  environment = {
    # disable stub-ld, this exists to kill dynamically linked executables, since they cannot work
    # on NixOS, however we know that so we don't need to see the warning
    stub-ld.enable = false;
  };

  programs = {
    # this is on by default. but I don't use nano
    nano.enable = false;
  };

  # this can allow us to save some storage space
  fonts.fontDir.decompressFonts = true;
}
