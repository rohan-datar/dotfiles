{ inputs, ... }:
let
  sharedNix =
    {
      pkgs,
      config,
      lib,
      _class,
      ...
    }:
    let
      sudoers = if (_class == "nixos") then "@wheel" else "@admin";
    in
    {
      age.secrets.nix-access-tokens = {
        file = ../secrets/nix-access-tokens.conf.age;
      };

      nix = {
        gc = {
          automatic = true;
          options = "--delete-older-than 10d";
        };

        channel.enable = false;

        settings = {
          substituters = [
            "https://cache.nixos.org/"
            "https://cache.nixos-cuda.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          ];
          extra-substituters = [
            "https://noctalia.cachix.org"
            "https://cache.numtide.com"
          ];
          extra-trusted-public-keys = [
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];

          allowed-users = [ sudoers ];
          trusted-users = [ sudoers ];

          system-features = [
            "nixos-test"
            "kvm"
            "recursive-nix"
            "big-parallel"
          ];

          sandbox = pkgs.stdenv.hostPlatform.isLinux;
          max-jobs = "auto";
          log-lines = 30;
          warn-dirty = false;
          experimental-features = [
            "nix-command"
            "flakes"
            "cgroups"
          ];
          http-connections = 50;
        };

        extraOptions = ''
          !include ${config.age.secrets.nix-access-tokens.path}
        '';
      };
    };
in
{
  flake.modules.nixos.nix = {
    imports = [ sharedNix ];
    config = {
      nix = {
        gc.dates = "Mon *-*-* 03:00";
        optimise = {
          automatic = true;
          dates = [ "04:00" ];
        };
        settings.use-cgroups = true;
      };
    };
  };

  flake.modules.darwin.nix = {
    imports = [ sharedNix ];
    config = {
      age.identityPaths = [
        "/Users/rohandatar/.ssh/id_ed25519"
        "/Users/rohandatar/.ssh/id_rsa"
      ];

      nix = {
        enable = true;
        gc.interval = {
          Hour = 3;
          Minute = 15;
        };
        settings.extra-platforms = [
          "aarch64-darwin"
          "x86-64-darwin"
        ];
      };
    };
  };
}
