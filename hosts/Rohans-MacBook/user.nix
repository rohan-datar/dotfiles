{ self, ... }:
{
  home-manager.users.rohandatar = {
    imports = [
      self.modules.homeManager.rohandatar
      self.modules.homeManager.neovim-full
    ];

    programs = {
      bat.enable = true;
      carapace.enable = true;
    };
  };
}
