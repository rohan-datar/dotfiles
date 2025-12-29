{ config, ... }:
{
  programs.zsh = {
    dotDir = "${config.xdg.configHome}/zsh";
    # we're only using this config in graphical environments
    inherit (config.olympus.aspects.graphical) enable;
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-syntax-highlighting"; }
        { name = "zsh-users/zsh-completions"; }
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "Aloxaf/fzf-tab"; }
        { name = "ael-code/zsh-colored-man-pages"; }
        { name = "davidde/git"; }
        { name = "jeffreytse/zsh-vi-mode"; }
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
    };

    shellAliases = {
      lg = "lazygit";
      c = "clear";
      cat = "bat";
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
