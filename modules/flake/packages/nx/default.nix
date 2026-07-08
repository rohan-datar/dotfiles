{
  perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      packages.nx = pkgs.writeShellApplication {
        name = "nx";
        text = builtins.readFile ./nx.sh;
        # Minimal runtime deps for portability when using 'nix run .#nx'.
        # Use the wrapped git so commits get the configured author identity
        # (GIT_CONFIG_GLOBAL) rather than the bare inner git.
        runtimeInputs = [
          pkgs.nix
          config.packages.git
          pkgs.uutils-coreutils-noprefix # date, hostname, readlink, etc.
          pkgs.findutils # 'find' used by fallback formatter
          pkgs.gawk # for the HM generations fallback
          pkgs.gnugrep
          pkgs.nh
          pkgs.libnotify
        ];
      };

      # 2) App (lets you 'nix run .#nx -- <subcommand>')
      apps.nx = {
        program = "${config.packages.nx}/bin/nx";
        meta.description = "My helper script for rebuilding and updating my config";
      };
    };
}
