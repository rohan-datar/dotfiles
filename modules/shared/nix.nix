{
  pkgs,
  _class,
  ...
}: let
  sudoers =
    if (_class == "nixos")
    then "@wheel"
    else "@admin";
in {
  nix = {
    # set up garbage collection to run <on the time frame specified per system>, and removing packages after 10 days
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };

    # disable usage of nix channels
    channel.enable = false;

    settings = {
      # https://github.com/NixOS/nix/issues/7273
      # auto-optimise-store = true;

      # users or groups which are allowed to do anything with the Nix daemon
      allowed-users = [sudoers];
      # users or groups which are allowed to manage the nix store
      trusted-users = [sudoers];

      # supported system features
      system-features = [
        "nixos-test"
        "kvm"
        "recursive-nix"
        "big-parallel"
      ];

      # build inside sandboxed environments
      # we only enable this on linux because it servirly breaks on darwin
      sandbox = pkgs.stdenv.hostPlatform.isLinux;

      # let the system decide the number of max jobs
      max-jobs = "auto";

      # show more log lines for failed builds, as this happens a lot and is useful
      log-lines = 30;

      warn-dirty = false;
      experimental-features = [
        "nix-command"
        "flakes"
        # allow usage of the pipe operator in nix expressions
        "pipe-operator"
      ];

      # maximum number of parallel TCP connections used to fetch imports and binary caches, 0 means no limit
      http-connections = 50;
    };
  };
}
