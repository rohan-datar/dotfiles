{ inputs, ... }:
{
  flake.modules.nixos.noctalia-greeter =
    { config, lib, ... }:
    {
      imports = [
        inputs.noctalia-greeter.nixosModules.default
      ];

      options.services.displayManager.noctalia-greeter = {
        enable = lib.mkEnableOption "noctalia-greeter (replaces SDDM)";
      };

      config = lib.mkIf config.services.displayManager.noctalia-greeter.enable {
        programs.noctalia-greeter.enable = true;

        services.displayManager.sddm.enable = lib.mkForce false;
      };
    };
}
