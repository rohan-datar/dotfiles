{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../common
    ./hypr
  ];

  home.packages = with pkgs; [
    blueman
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    swaynotificationcenter
    pavucontrol
    brightnessctl
    networkmanager_dmenu
    networkmanagerapplet
    ghostty

    #fonts

    maple-mono.NF
    nerd-fonts.meslo-lg
    font-awesome
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-compact
    inputs.apple-fonts.packages.${pkgs.system}.sf-compact-nerd
    inputs.apple-fonts.packages.${pkgs.system}.ny
    inputs.apple-fonts.packages.${pkgs.system}.ny-nerd
  ];
  fonts.fontconfig.enable = true;

  programs.fzf.enable = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rdatar";
  home.homeDirectory = "/home/rdatar";
}
