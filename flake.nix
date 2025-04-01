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

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Zen browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catpuccin color scheme
    catppuccin.url = "github:catppuccin/nix";

    # hyprland window manager
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    nix-homebrew,
    home-manager,
    catppuccin,
    agenix,
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
        catppuccin.nixosModules.catppuccin
        agenix.nixosModules.default
      ];
    };

    # config for macbook
    darwinConfigurations.${macbook} = nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/${macbook}/configuration.nix
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
        agenix.darwinModules.default
      ];
    };

    homeConfigurations = {
      rdatar = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home-manager/platforms/linux/home.nix
          catppuccin.homeModules.catppuccin
        ];
      };

      rohandatar = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home-manager/platforms/macos/home.nix
          catppuccin.homeModules.catppuccin
        ];
      };
    };
  };
}
