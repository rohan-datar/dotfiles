{
  description = "Nix config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Zen browser
    zen-browser.url = "github:rohan-datar/zen-browser-flake";
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    nix-homebrew,
    ...
  } @ inputs: let
    home-desktop = "home-desktop";
    macbook = "macbook";
  in {
    # config for desktop
    nixosConfigurations.${home-desktop} = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/${home-desktop}/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };

    # config for macbook
    darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/${macbook}/configuration.nix
        # inputs.home-manager.darwinModules.default
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            # Apple Silicon Only
            enableRosetta = true;

            user = "rohandatar";

            autoMigrate = true;
          };
        }
      ];
    };
  };
}
