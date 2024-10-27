{ config, pkgs, ... }:
let
  tmux-nerd-font-window-name =  pkgs.tmuxPlugins.mkTmuxPlugin
  {
    pluginName = "tmux-nerd-font-window-name";
    version = "v2.1.2";
    src = pkgs.fetchFromGithub {
      owner = "joshmedeski";
      repo = "tmux-nerd-font-window-name";
      rev = "be794baa114de855bf3069c60765a49508935edc";
    };
  };
in
{
  programs.tmux = {
    enable = true;

    # set the prefix
    prefix = "C-s";

    # set the terminal
    terminal = "tmux-256color";

    # set vi key-mode
    key-mode = "vi";

    # enable mouse support
    mouse = true;

    plugins = with pkgs; [
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
  };
}
