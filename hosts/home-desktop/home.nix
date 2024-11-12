{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home-manager
    ./hypr/
  ];

  programs = {

    kitty = {
      enable = true;
      font = {
        name =  "Maple Mono NF";
        size = 19;
      };
      settings = {
        background_opacity = 0.85;
        background_blur = 16;
      };
    };
  };

  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    x11.enable = true;
    name = "Adwaita";
    size = 38;
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
