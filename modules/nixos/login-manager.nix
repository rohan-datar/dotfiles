{ inputs, ... }:
{
  flake.modules.nixos.login-manager =
    {
      self,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.noctalia-greeter.nixosModules.default
      ];
      config = {
        programs.niri = {
          enable = true;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
        };

        # services = {
        #   displayManager = {
        #     sddm = {
        #       enable = false;
        #       package = pkgs.kdePackages.sddm;
        #       autoNumlock = true;
        #       settings.General.RememberLastSession = false;
        #       wayland = {
        #         enable = true;
        #         compositor = "kwin";
        #       };
        #     };
        #     defaultSession = "niri";
        #   };
        # };
        programs.noctalia-greeter = {
          enable = true;
          greeter-args = "--session Niri";
        };
      };
    };
}
