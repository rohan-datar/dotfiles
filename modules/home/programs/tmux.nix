{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    # set the prefix
    prefix = "C-s";

    # set the terminal
    terminal = "tmux-256color";

    # set vi key-mode
    keyMode = "vi";

    # enable mouse support
    mouse = true;

    shell = "${pkgs.fish}/bin/fish";

    plugins = with pkgs; [
      {

        plugin = tmuxPlugins.vim-tmux-navigator;
        extraConfig = ''
          set -g @vim_navigator_no_mappings 1
          is_vim="ps -o state = -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
          bind-key -n C-w if-shell "$is_vim" "send-keys C-w" "switch-client -T vimtable"
          bind-key -T vimtable h select-pane -L \; switch-client -T root
          bind-key -T vimtable j select-pane -D \; switch-client -T root
          bind-key -T vimtable k select-pane -U \; switch-client -T root
          bind-key -T vimtable l select-pane -R \; switch-client -T root
        '';
      }

      {
        plugin = tmuxPlugins.tmux-fzf;
        extraConfig = ''
          TMUX_FZF_LAUNCH_KEY="Space"
        '';
      }

      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
        '';
      }
    ];

    extraConfig = ''
      # kill sessions easily
      bind X confirm-before kill-session

      unbind %
      bind | split-window -h

      unbind '"'
      bind - split-window -v

      bind j resize-pane -D 5
      bind k resize-pane -U 5
      bind l resize-pane -R 5
      bind h resize-pane -L 5

      bind -r m resize-pane -Z


      bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
      bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

      unbind -T copy-mode-vi MouseDragEnd1Pane # don't exit copy mode when dragging with mouse

      set-option -g status-position top
      # set -gu default-command
      # set -g default-shell "$SHELL"
    '';
  };
}
