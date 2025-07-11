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
        {name = "ael-code/zsh-colored-man-pages";}
        {name = "davidde/git";}
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
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
      c = "clear";
      cat = "bat";
      gbc = "sudo nix-collect-garbage --delete-older-than 30d && nix-collect-garbage --delete-older-than 30d";
    };

    initContent = ''
      # Keybindings
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

      # Shell integrations
      eval "$(fzf --zsh)"
      eval "$(zoxide init --cmd cd zsh)"

      any-nix-shell zsh --info-right | source /dev/stdin
    '';
  };
}
