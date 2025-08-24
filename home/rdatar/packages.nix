{pkgs, ...}: {
  olympus.packages = with pkgs; [
    blueman
    hyprshot
    hyprlock
    hypridle
    pavucontrol
    brightnessctl
    fuzzel
  ];
}
