_: {
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

        programs.noctalia = {
          enable = true;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia;
          systemd.enable = true;
        };

        services.displayManager.noctalia-greeter = {
          enable = true;
          extraArgs = [
            "--session"
            "Niri"
          ];
        };

        # noctalia's greeter sync escalates via pkexec, which needs the setuid
        # wrapper (no longer enabled by security.polkit.enable alone)
        security.polkit.enablePkexecWrapper = true;
      };
    };
}
