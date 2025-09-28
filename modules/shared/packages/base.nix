{
  pkgs,
  inputs,
  self,
  ...
}:
{
  # shared with all systems
  olympus.packages = {
    inherit (pkgs)
      uutils-coreutils-noprefix
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
      ;
    agenix = inputs.agenix.packages.${pkgs.system}.default;
    inherit (self.packages.${pkgs.system}) nx;
  };
}
