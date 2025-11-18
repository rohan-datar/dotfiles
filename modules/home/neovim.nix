{
  inputs,
  neovimPkg ? "full",
  ...
}:
{
  imports = [ inputs.editorconfig.homeModules.nixCats ];

  nixCats.enable = true;
  nixCats.packageNames = [ neovimPkg ];

  home.sessionVariables.EDITOR = "nvim";
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };
}
