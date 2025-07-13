{pkgs, ...}: {
  programs.zsh = {
    enable = true;

    # this overrides the default shell for interactive sessions to be fish
    # but keeps bash in other scenarios to avoid compatibility issues
    # see https://wiki.nixos.org/wiki/Fish#section_Setting_fish_as_default_shell
    initExtra = ''
      if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
      then
          exec fish -l
      fi
    '';

    zplug = {
      enable = true;
      plugins = [
        {name = "zsh-users/zsh-syntax-highlighting";}
        {name = "zsh-users/zsh-completions";}
        {name = "zsh-users/zsh-autosuggestions";}
        {name = "Aloxaf/fzf-tab";}
        {name = "ael-code/zsh-colored-man-pages";}
        {name = "davidde/git";}
        {name = "jeffreytse/zsh-vi-mode";}
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
