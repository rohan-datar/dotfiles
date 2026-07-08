{
  flake.modules.nixos.bluetooth = {
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
