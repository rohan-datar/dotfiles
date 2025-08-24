{ lib, config, ... }:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.olympus.system.bluetooth;
in
{
  options.olympus.system.bluetooth = {
    enable = mkEnableOption "Enable bluetooth related configurations" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman = {
      enable = true;
    };

    boot.kernelModules = [ "btusb" ];
  };
}
