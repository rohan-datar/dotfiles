_: {
  flake.modules.homeManager.neovim-full =
    { inputs, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      home.packages = [
        inputs.editorconfig.packages.${system}.nvim-full
      ];

      home.sessionVariables.EDITOR = "nvim";
      home.shellAliases = {
        vi = "nvim";
        vim = "nvim";
        vimdiff = "nvim -d";
      };
    };
}
