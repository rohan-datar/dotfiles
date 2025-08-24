{
  _class = "nixos";

  import = [
    # keep-sorted start
    ../shared
    ./hardware
    ./system
    ./graphical
    ./programs
    ./services
    ./console.nix
    ./documentation.nix
    ./nix.nix
    ./emulation.nix
    ./localization.nix
    ./shell.nix
    # keep-sorted end
  ];
}
