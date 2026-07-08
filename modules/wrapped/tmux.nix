_: {
  flake.wrappers.tmux =
    {
      wlib,
      pkgs,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.tmux ];

      prefix = "C-s";
      terminal = "tmux-256color";
      modeKeys = "vi";
      statusKeys = "vi";
      mouse = true;
      disableConfirmationPrompt = false;

      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = vim-tmux-navigator;
          configBefore = ''
            set -g @vim_navigator_no_mappings 1
          '';
          configAfter = ''
            is_vim="ps -o state = -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?$'"
            bind-key -n C-w if-shell "$is_vim" "send-keys C-w" "switch-client -T vimtable"
            bind-key -T vimtable h select-pane -L \; switch-client -T root
            bind-key -T vimtable j select-pane -D \; switch-client -T root
            bind-key -T vimtable k select-pane -U \; switch-client -T root
            bind-key -T vimtable l select-pane -R \; switch-client -T root
          '';
        }
        {
          plugin = tmux-fzf;
          configBefore = ''
            TMUX_FZF_LAUNCH_KEY="Space"
          '';
        }
        {
          plugin = catppuccin;
          configBefore = ''
            set -g @catppuccin_flavor 'mocha'
          '';
        }
      ];

      configAfter = ''
        # kill sessions easily
        bind X confirm-before kill-session

        unbind %
        bind | split-window -h

        unbind "
        bind - split-window -v

        bind j resize-pane -D 5
        bind k resize-pane -U 5
        bind l resize-pane -R 5
        bind h resize-pane -L 5

        bind -r m resize-pane -Z

        bind-key -T copy-mode-vi 'v' send -X begin-selection
        bind-key -T copy-mode-vi 'y' send -X copy-selection

        unbind -T copy-mode-vi MouseDragEnd1Pane

        set-option -g status-position top
      '';
    };
}
