{
  flake.modules.homeManager.bat = {
    programs.bat = {
      enable = true;
      config = {
        style = "numbers";
      };
    };
  };
}
