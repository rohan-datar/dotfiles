{
  perSystem =
    { pkgs, ... }:
    {
      wrappers = {
        control_type = "exclude";
        packages = {
          # niri is a Linux-only compositor; don't try to build the wrapper on Darwin.
          niri = pkgs.stdenv.hostPlatform.isDarwin;
        };
      };
    };
}
