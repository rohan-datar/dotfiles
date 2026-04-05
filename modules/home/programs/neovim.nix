{
  inputs,
  pkgs,
  neovimPkg ? "full",
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  home.packages = [
    inputs.editorconfig.packages.${system}."nvim-${neovimPkg}"
  ];

  home.sessionVariables.EDITOR = "nvim";
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };
}
