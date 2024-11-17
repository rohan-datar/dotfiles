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

    # catpuccin color scheme
    catppuccin.url = "github:catppuccin/nix";

    # hyprland window manager
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs =
    { self
    , nixpkgs
    , nix-darwin
    , nix-homebrew
    , home-manager
    , catppuccin
    , ...
    } @ inputs:
    let
      home-desktop = "home-desktop";
      macbook = "macbook";
    in
    {
      # config for desktop
      nixosConfigurations.${home-desktop} = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${home-desktop}/configuration.nix
          inputs.catppuccin.nixosModules.catppuccin
        ];
      };

      # config for macbook
      darwinConfigurations.${macbook} = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
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
        ];
      };

      homeConfigurations = {
        rdatar = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./hosts/${home-desktop}/home.nix
            catppuccin.homeManagerModules.catppuccin
          ];
        };

        rohandatar = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./hosts/${macbook}/home.nix
            catppuccin.homeManagerModules.catppuccin
          ];
        };
      };
    };
}
