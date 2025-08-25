{
  self,
  pkgs,
  inputs,
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
      zoxide
      btop
      bat
      comma
      any-nix-shell
      ;
    agenix = inputs.agenix.packages.${pkgs.system}.default;
    inherit (self.packages.${pkgs.system}) nx;
  };
}
