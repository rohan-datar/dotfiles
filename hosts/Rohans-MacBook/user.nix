{ self, ... }:
{
  home-manager.users.rohandatar = {
    imports = [
      self.modules.homeManager.rohandatar
      self.modules.homeManager.neovim-full
      self.modules.homeManager.org-notes-sync
    ];

    services.org-notes-sync = {
      enable = true;
      hostId = "macbook";
      initialSource = "path1";
      enableGitSnapshots = true;
    };

    programs = {
      bat.enable = true;
      carapace.enable = true;
    };
  };
}
