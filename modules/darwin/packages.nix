_: {
  flake.modules.darwin.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
          libwebp
          m-cli
          ;
      };
    };
}
