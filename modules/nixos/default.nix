{
  _class = "nixos";

  imports = [
    # keep-sorted start
    ../shared
    ./console.nix
    ./documentation.nix
    ./emulation.nix
    ./extras.nix
    ./graphical
    ./hardware
    ./localization.nix
    ./nix.nix
    ./programs
    ./services
    ./shell.nix
    ./system
    # keep-sorted end
  ];
}
