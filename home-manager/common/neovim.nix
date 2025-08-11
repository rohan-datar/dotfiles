{
  lib,
  config,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
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
      tree-sitter-grammars.tree-sitter-swift

      (tree-sitter.buildGrammar {
        language = "leaf";
        version = "7ca9aca";
        src = pkgs.fetchFromGitHub {
          owner = "visualbam";
          repo = "tree-sitter-leaf";
          rev = "7ca9aca731a3cd1b8b38743e88d828465fc6d480";
          sha256 = "";
        };
      })

      nodePackages_latest.vscode-json-languageserver
      fzf
      lua-language-server
      nixd
      go
      gopls
      gofumpt
      stylua
      cargo
      rustc
      nixfmt-rfc-style
      zls
      ripgrep
      delve
      yamllint
      jq
      yq
      jdt-language-server
      sourcekit-lsp
      texliveFull
      sqls
      htmx-lsp
      superhtml
    ];
  };
  home.file = {
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };
  };
  # Conditionally add xdg.desktopEntries for Linux
  xdg.desktopEntries = lib.optionalAttrs pkgs.stdenv.isLinux {
    neovim = {
      name = "Neovim";
      genericName = "editor";
      exec = "nvim -f %F";
      mimeType = [
        "text/html"
        "text/xml"
        "text/plain"
        "text/english"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-tex"
        "application/x-shellscript"
      ];
      terminal = false;
      type = "Application";
    };
  };
}
