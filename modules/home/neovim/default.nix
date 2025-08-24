# NOTE: This will be replaced eventually
{pkgs, ...}: {
  programs.neovim = {
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs; [
      vimPlugins.nvim-treesitter.withAllGrammars
      vimPlugins.nvim-treesitter
    ];
    extraPackages = with pkgs; [
      tree-sitter
      tree-sitter-grammars.tree-sitter-lua
      tree-sitter-grammars.tree-sitter-nix
      tree-sitter-grammars.tree-sitter-go
      tree-sitter-grammars.tree-sitter-python
      tree-sitter-grammars.tree-sitter-bash
      tree-sitter-grammars.tree-sitter-regex
      tree-sitter-grammars.tree-sitter-markdown
      tree-sitter-grammars.tree-sitter-json
      tree-sitter-grammars.tree-sitter-latex
      tree-sitter-grammars.tree-sitter-sql

      nodePackages_latest.vscode-json-languageserver
      fzf
      lua-language-server
      nil
      go
      gopls
      gofumpt
      stylua
      cargo
      rustc
      nixfmt
      zls
      ripgrep
      delve
      yamllint
      jq
      yq
      jdt-language-server
      sourcekit-lsp
      superhtml
    ];
  };
  home.file = {
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };
  };
}
