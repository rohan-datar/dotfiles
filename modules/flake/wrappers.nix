{
  perSystem =
    { pkgs, ... }:
    {
      wrappers = {
        control_type = "exclude";
        packages = {
          # niri and noctalia are Linux-only Wayland shells; don't try to
          # build their wrappers on Darwin.
          niri = pkgs.stdenv.hostPlatform.isDarwin;
          noctalia = pkgs.stdenv.hostPlatform.isDarwin;
        };
      };
    };
}
