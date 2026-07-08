_: {
  flake.modules.homeManager.direnv =
    {
      pkgs,
      self,
      ...
    }:
    {
      programs.direnv = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.direnv;
      };
    };
}
