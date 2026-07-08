{
  flake.modules.nixos.login-manager =
    {
      self,
      pkgs,
      ...
    }:
    {
      config = {
        programs.niri = {
          enable = true;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
        };

        services = {
          displayManager.sddm = {
            enable = true;
            package = pkgs.kdePackages.sddm;
            autoNumlock = true;
            settings.General.RememberLastSession = false;
            wayland = {
              enable = true;
              compositor = "kwin";
            };
          };
          displayManager.defaultSession = "niri";
        };
      };
    };
}
