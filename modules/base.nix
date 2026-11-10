{
  inputs,
  self,
  lib,
  ...
}:
let
  mkBasePackages =
    pkgs:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      wrapped = self.packages.${system};
      # hiPrio so the wrapped versions shadow any plain ones installed by
      # other modules (e.g. programs.fish.enable installs pkgs.fish).
      hi = lib.mapAttrsToList (_: p: lib.hiPrio p) {
        inherit (wrapped)
          git
          fish
          tmux
          fzf
          starship
          eza
          ;
      };
    in
    hi
    ++ (builtins.attrValues {
      inherit (pkgs)
        uutils-coreutils-noprefix
        pciutils
        python3
        fd
        zoxide
        btop
        bat
        any-nix-shell
        ripgrep
        dysk
        lazygit
        gh
        just
        nh
        ;
      ragenix = inputs.ragenix.packages.${system}.default;
      # comma with a prebuilt nix-index database: never build the index locally
      # (that evaluates all of nixpkgs and took io down on 2026-11-09).
      comma = inputs.nix-index-database.packages.${system}.comma-with-db;
    });
in
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = mkBasePackages pkgs;
    };

  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      environment.systemPackages = mkBasePackages pkgs;
    };
}
