{
  flake.modules.nixos.emulation =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      getArch = system: lib.elemAt (lib.splitString "-" system) 0;
    in
    {
      boot.binfmt.registrations = lib.genAttrs config.boot.binfmt.emulatedSystems (system: {
        interpreter = "${pkgs.qemu}/bin/qemu-${getArch system}";
      });

      nix.settings.extra-sandbox-paths = [
        "/run/binfmt"
        (toString pkgs.qemu)
      ];

      boot.binfmt.emulatedSystems = lib.mkDefault (
        lib.filter (system: system != pkgs.stdenv.hostPlatform.system) [
          "x86_64-linux"
          "aarch64-linux"
          "i686-linux"
        ]
      );
    };
}
