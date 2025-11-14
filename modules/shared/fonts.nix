{
  inputs,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  fonts.packages = [
    pkgs.corefonts
    pkgs.maple-mono.NF
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.meslo-lg
    pkgs.nerd-fonts.symbols-only
    pkgs.font-awesome
    inputs.apple-fonts.packages.${system}.sf-pro
    inputs.apple-fonts.packages.${system}.sf-pro-nerd
    inputs.apple-fonts.packages.${system}.sf-compact
    inputs.apple-fonts.packages.${system}.sf-compact-nerd
    inputs.apple-fonts.packages.${system}.ny
    inputs.apple-fonts.packages.${system}.ny-nerd
  ];
}
