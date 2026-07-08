_: {
  flake.wrappers.fzf =
    {
      wlib,
      pkgs,
      ...
    }:
    {
      imports = [ wlib.modules.default ];

      package = pkgs.fzf;

      env.FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border";
    };
}
