{
    _class = "darwin";

    imports = [
        # keep-sorted start
        ../shared/
        ./brew
        ./system
        ./documentation.nix
        ./extras.nix
        ./nix.nix
        ./packages.nix
        ./shell.nix
        # keep-sorted end
    ];
}
