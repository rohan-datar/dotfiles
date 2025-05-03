{...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
  settings = {
    cursor-style = "block";
    # fonts with fallback
    font-family = [
      "Maple Mono NF"
      "MesloLGS Nerd Font Mono"
      "FiraCode Nerd Font Mono"
    ];
    font-size = 15;
    # background
    background-opacity = 0.85;
    background-blur-radius = 16;
    window-decoration = false;
  };
}
