{
  imports = [
    #keep-sorted start
    ./programs
    ./ui
    ./fonts.nix
    ./packages.nix
    #keep-sorted end
  ];

  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
