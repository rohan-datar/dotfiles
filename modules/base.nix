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
          nx
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
        comma
        any-nix-shell
        ripgrep
        dysk
        lazygit
        gh
        ;
      agenix = inputs.agenix.packages.${system}.default;
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
