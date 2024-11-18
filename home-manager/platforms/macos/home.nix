{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../common
  ];
  home.file = {
    ".config/aerospace/aerospace.toml" = {
      source = ./aerospace/aerospace.toml;
    };

    ".config/sketchybar" = {
      source = ./sketchybar;
      recursive = true;
    };
  };
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rohandatar";
  home.homeDirectory = "/Users/rohandatar";
}
