{
  flake.modules.nixos.firmware = {
    imports = [
      (
        { config, ... }:
        {
          # firmware updater for machine hardware
          services.fwupd = {
            enable = true;
            daemonSettings.EspLocation = config.boot.loader.efi.efiSysMountPoint;
          };
        }
      )
    ];

    config = {
      # Enables non-free firmware on devices, this is usually done if
      # `nixos-generate-config` cannot detect what firmware is needed for the device
      hardware.enableRedistributableFirmware = true;
    };
  };
}
