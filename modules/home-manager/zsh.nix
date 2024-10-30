{pkgs, ...}: {
  programs.zsh = {
    enable = true;

    zplug = {
      enable = true;
      plugins = [
        {name = "zsh-users/zsh-syntax-highlighting";}
        {name = "zsh-users/zsh-completions";}
        {name = "zsh-users/zsh-autosuggestions";}
        {name = "Aloxaf/fzf-tab";}
        {name = "softmoth/zsh-vim-mode";}
      ];
    };

    history = {
      append = true;
      ignoreAllDups = true;
      ignoreDups = true;
      expireDuplicatesFirst = true;
      ignoreSpace = true;
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
