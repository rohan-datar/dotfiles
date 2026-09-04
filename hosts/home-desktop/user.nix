{ self, ... }:
{
  services.displayManager.autoLogin.enable = false;
  services.displayManager.autoLogin.user = "rdatar";

  home-manager.users.rdatar = {
    imports = [
      self.modules.homeManager.rdatar
      self.modules.homeManager.neovim-full
      self.modules.homeManager.org-notes-sync
    ];

    services.org-notes-sync = {
      enable = true;
      hostId = "home-desktop";
      initialSource = "path2";
      scheduleOffsetMinutes = 5;
    };

    programs = {
      bat.enable = true;
      carapace.enable = true;
    };
  };
}
