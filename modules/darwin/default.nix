{
    _class = "darwin";

    imports = [
        ../shared/
        ./brew
        ./system
        ./documentation.nix
        ./extras.nix
        ./nix.nix
        ./packages.nix
    ];
}
