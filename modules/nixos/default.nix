{
  _class = "nixos";

  imports = [
    # keep-sorted start
    ../shared
    ./extras.nix
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
