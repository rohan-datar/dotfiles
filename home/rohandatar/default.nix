{
  imports = [
    # Trying out paneru; aerospace.nix is kept on disk for easy revert.
    ./paneru.nix
  ];

  home.username = "rohandatar";
  home.homeDirectory = "/Users/rohandatar";
}
