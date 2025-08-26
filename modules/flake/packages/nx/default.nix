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
        # Minimal runtime deps for portability when using 'nix run .#nx'
        runtimeInputs = with pkgs; [
          nix
          git
          uutils-coreutils-noprefix # date, hostname, readlink, etc.
          findutils # 'find' used by fallback formatter
          gawk # for the HM generations fallback
          gnugrep # not strictly required, but handy if you extend
          nh
          libnotify
        ];
      };

      # 2) App (lets you 'nix run .#nx -- <subcommand>')
      apps.nx = {
        program = "${config.packages.nx}/bin/nx";
        meta.description = "My helper script for rebuilding and updating my config";
      };
    };
}
