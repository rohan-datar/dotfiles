_: {
  flake.wrappers.git =
    {
      wlib,
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [ wlib.modules.default ];

      package = pkgs.git;

      constructFiles.gitattributes = {
        relPath = "gitattributes";
        content = "* text=auto";
      };

      constructFiles.gitconfig = {
        relPath = "gitconfig";
        content = lib.mkMerge [
          ''
            [core]
              attributesfile = ${config.constructFiles.gitattributes.path}

            [user]
              email = "me@rohandatar.com"
              name = "Rohan Datar"

            [alias]
              diff = "diff --word-diff"
              blame = "blame -C -C -C"

            [merge]
              conflictstyle = "diff3"

            [rerere]
              enabled = true
          ''
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux ''

            [credential]
              helper = "store"
          '')
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''

            [credential]
              helper = "osxkeychain"
          '')
        ];
      };

      env.GIT_CONFIG_GLOBAL = config.constructFiles.gitconfig.path;
    };
}
