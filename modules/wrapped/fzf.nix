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
    };
}
