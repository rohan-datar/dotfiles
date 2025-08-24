{
  config,
  pkgs,
  ...
}:
{
  users.users.rohandatar = {
    name = "rohandatar";
    home = "/Users/rohandatar";
  };

  olympus = {
    graphical.enable = true;
  };
}
