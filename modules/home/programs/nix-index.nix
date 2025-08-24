{
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.nix-index-database = {
    comma.enable = true;
  };
}
