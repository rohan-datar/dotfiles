{ inputs, self, ... }:
{
  # Reusable headless NixOS installer ISO for homelab bare-metal provisioning
  flake.nixosConfigurations.installer-iso = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.installer-iso ];
  };

  flake.modules.nixos.installer-iso =
    { pkgs, lib, ... }:
    {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        self.modules.nixos.rdatar
      ];

      nixpkgs = {
        hostPlatform = "x86_64-linux";
        config.allowUnfree = true;
      };

      image.baseName = lib.mkForce "nixos-homelab-installer";
      # zstd builds 4-5x faster than the default xz squashfs compression.
      isoImage.squashfsCompression = "zstd -Xcompression-level 6";

      networking = {
        hostName = "nixos-installer";
        useDHCP = lib.mkDefault true;
      };

      # Announce nixos-installer.local over mDNS so headless boots on the N100
      # or ML350 can be reached without looking up the DHCP lease first.
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        settings.publish = {
          disable-publishing = false;
          publish-addresses = true;
          publish-workstation = true;
        };
      };

      # Enable SSH immediately on boot with rdatar/root authorizedKeys from
      # self.modules.nixos.rdatar so nixos-anywhere can provision unattended.
      systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = false;
        };
      };

      # ML350 Gen9 hardware support inside the live installer:
      # - sg: exposes disks behind the Smart Array P440ar before HBA cutover
      # - ixgbe allow_unsupported_sfp=1: allows non-HPE SFP+ DAC cables in the HP 560SFP+
      boot = {
        kernelModules = [ "sg" ];
        extraModprobeConfig = ''
          options ixgbe allow_unsupported_sfp=1
        '';
      };

      hardware.enableRedistributableFirmware = true;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      environment.systemPackages = [
        inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
        pkgs.curl
        pkgs.ethtool
        pkgs.git
        pkgs.gptfdisk
        pkgs.htop
        pkgs.ipmitool
        pkgs.jq
        pkgs.nvme-cli
        pkgs.parted
        pkgs.pciutils
        pkgs.smartmontools
        pkgs.tmux
        pkgs.usbutils
      ];
    };
}
