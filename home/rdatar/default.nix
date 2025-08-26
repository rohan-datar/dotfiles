{
  imports = [
    #keep-sorted start
    ./fonts.nix
    ./packages.nix
    ./programs
    ./ui
    #keep-sorted end
  ];

  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
