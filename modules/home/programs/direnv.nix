{config, ...}: {
  programs.direnv = {
    inherit (config.olympus.aspects.graphical) enable;
    silent = true;

    # faster, persistent implementation of use_nix and use_flake
    nix-direnv = {
      enable = true;
    };

    # store direnv in cache and not per project
    # <https://github.com/direnv/direnv/wiki/Customizing-cache-location#hashed-directories>
    stdlib = ''
      : ''${XDG_CACHE_HOME:=$HOME/.cache}
      declare -A direnv_layout_dirs

      direnv_layout_dir() {
        echo "''${direnv_layout_dirs[$PWD]:=$(
          echo -n "$XDG_CACHE_HOME"/direnv/layouts/
          echo -n "$PWD" | sha1sum | cut -d ' ' -f 1
        )}"
      }
    '';
  };
}
