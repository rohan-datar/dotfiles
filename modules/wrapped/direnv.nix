_: {
  flake.wrappers.direnv =
    {
      wlib,
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [ wlib.modules.default ];

      package = pkgs.direnv;

      constructFiles.direnvTOML = {
        relPath = "direnv/direnv.toml";
        content = builtins.toJSON {
          global = {
            log_format = "-";
            log_filter = "^$";
          };
        };
        builder = ''${pkgs.remarshal}/bin/json2toml "$1" "$2"'';
      };

      constructFiles.nixDirenv = {
        relPath = "direnv/lib/nix-direnv.sh";
        builder = "cp ${lib.escapeShellArg "${pkgs.nix-direnv}/share/nix-direnv/direnvrc"} \"$2\"";
      };

      constructFiles.direnvrc = {
        relPath = "direnv/direnvrc";
        content = ''
          : ''${XDG_CACHE_HOME:=$HOME/.cache}
          declare -A direnv_layout_dirs

          direnv_layout_dir() {
            echo "''${direnv_layout_dirs[$PWD]:=$XDG_CACHE_HOME/direnv/layouts/$(echo -n "$PWD" | sha1sum | cut -d ' ' -f 1)}"
          }
        '';
      };

      env = {
        XDG_CONFIG_HOME = placeholder "out";
        DIRENV_LOG_FORMAT = "";
      };
    };
}
