_: {
  flake.modules.homeManager.git =
    {
      pkgs,
      self,
      ...
    }:
    {
      programs.git = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.git;
      };
    };
}
