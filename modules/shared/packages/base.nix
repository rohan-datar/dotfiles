{
  pkgs,
  inputs,
  self,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  # shared with all systems
  olympus.packages = {
    inherit (pkgs)
      uutils-coreutils-noprefix
      pciutils
      python3
      fd
      git
      tmux
      fzf
      zoxide
      btop
      bat
      comma
      any-nix-shell
      starship
      ripgrep
      dysk
      lazygit
      ;
    agenix = inputs.agenix.packages.${system}.default;
    inherit (self.packages.${system}) nx;
  };
}
