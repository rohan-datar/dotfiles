{pkgs, ...}: let
  zsh-vim-mode = {
    name = "zsh-vim-mode";
    file = "zsh-vim-mode.plugin.zsh";
    src = pkgs.fetchFromGithub {
      owner = "softmoth";
      repo = "zsh-vim-mode";
      rev = "1f9953b7d6f2f0a8d2cb8e8977baa48278a31eab";
    };
  };
in {
  programs.zsh = {
    enable = true;

    plugins = with pkgs; [
      zsh-vim-mode
    ];

    zplug = {
      enable = true;
      plugins = [
        {name = "zsh-syntax-highlighting";}
        {name = "zsh-completions";}
        {name = "zsh-autosuggestions";}
        {name = "zsh-fzf-tab";}
      ];
    };

    history = {
      append = true;
      IgnoreAllDups = true;
      IgnoreDups = true;
      expireDuplicatesFirst = true;
      IgnoreSpace = true;
      share = true;
      save = 5000; # number of lines to save
      # path = ~/.zsh_history;
    };

    shellAliases = {
      lg = "lazygit";
    };

    initExtra = ''
      # Keybindings
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${s.:. LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

      # Shell integrations
      eval "$(fzf --zsh)"
      eval "$(zoxide init --cmd cd zsh)"
    '';

    oh-my-zsh = {
      package = pkgs.oh-my-zsh;
      enable = true;
      plugins = [
        "git"
        "sudo"
        "command-not-found"
        "colored-man-pages"
        "tmux"
      ];
    };
  };
}
