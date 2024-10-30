{
  config,
  pkgs,
  ...
}: let
  tmux-nerd-font-window-name =
    pkgs.tmuxPlugins.mkTmuxPlugin
    {
      pluginName = "tmux-nerd-font-window-name";
      version = "v2.1.2";
      src = pkgs.fetchFromGitHub {
        owner = "joshmedeski";
        repo = "tmux-nerd-font-window-name";
        rev = "be794baa114de855bf3069c60765a49508935edc";
        sha256 = "sha256-pHciRdF/t/h2geOPI0d6URgPmA0mlLb3fNEbU5NRNKY=";
      };
    };
in {
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

    plugins = with pkgs; [
      tmux-nerd-font-window-name

      tmuxPlugins.vim-tmux-navigator

      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          # overall colors
          set -g @catppuccin_flavor 'mocha'

          # show an icon for the current window instead of *
          set -g @catppuccin_window_status "icon"

          # set the right of the window to arrow style and have an arrow between the window number an text
          set -g @catppuccin_window_right_separator "█"
          set -g @catppuccin_window_middle_separator "  "

          # color the currently active window
          set -g @catppuccin_window_default_fill "none"
          set -g @catppuccin_window_current_fill "all"

          # show the currently running process in the window
          set -g @catppuccin_window_default_text "#W"
          set -g @catppuccin_window_current_text "#W"

          # set the style of the status module
          set -g @catppuccin_status_left_separator "█"
          set -g @catppuccin_status_middle_separator ""
          set -g @catppuccin_status_connect_separator "yes"
          set -g @catppuccin_status_fill "all"

          # set which modules to display
          set -g @catppuccin_status_modules_right "date_time user session"
        '';
      }

      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }

      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
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
      set -gu default-command
      set -g default-shell "$SHELL"
    '';
  };
}
