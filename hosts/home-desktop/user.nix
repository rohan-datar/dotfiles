{ self, ... }:
{
  services.displayManager.autoLogin.enable = false;
  services.displayManager.autoLogin.user = "rdatar";

  programs.hyprland.enable = false;

  home-manager.users.rdatar = {
    imports = [
      self.modules.homeManager.rdatar
      self.modules.homeManager.neovim-full
    ];

    programs = {
      bat.enable = true;
      carapace.enable = true;
    };
  };
}
