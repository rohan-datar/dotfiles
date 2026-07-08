{ self, ... }:
{
  imports = [
    ./_internal/base.nix
    ./_internal/env.nix
    ./_internal/nix.nix
    ./_internal/bat.nix
    ./_internal/btop.nix
    ./_internal/carapace.nix
    ./_internal/direnv.nix
    ./_internal/git.nix
    ./_internal/nh.nix
    ./_internal/nix-index.nix
    ./_internal/ssh.nix
    ./_internal/zsh.nix
    ./_internal/neovim-full.nix
    ./_internal/zed.nix
    ./_internal/kitty.nix
    ./_internal/ghostty.nix
  ];

  flake.modules.homeManager.default = {
    imports = [
      self.modules.homeManager.base
      self.modules.homeManager.env
      self.modules.homeManager.nix
      self.modules.homeManager.bat
      self.modules.homeManager.btop
      self.modules.homeManager.carapace
      self.modules.homeManager.direnv
      self.modules.homeManager.git
      self.modules.homeManager.nh
      self.modules.homeManager.nix-index
      self.modules.homeManager.ssh
      self.modules.homeManager.zsh
      self.modules.homeManager.zed
      self.modules.homeManager.kitty
      self.modules.homeManager.ghostty
    ];
  };
}
