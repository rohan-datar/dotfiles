_: {
  flake.wrappers.eza =
    {
      wlib,
      pkgs,
      ...
    }:
    {
      imports = [ wlib.modules.default ];

      package = pkgs.eza;
    };
}
