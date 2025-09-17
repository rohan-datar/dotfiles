{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    generateCompletions = true;
    preferAbbrs = true;

    shellAbbrs = {
      lg = "lazygit";

      # ls aliases
      ls = "ls --color";
      lsa = "ls -lah";
      l = "ls -lah";
      ll = "ls -lh";
      la = "ls -lAh";
    };

    shellAliases = {
      cat = "bat";
    };

    plugins = [
      {
        name = "macos";
        inherit (pkgs.fishPlugins.macos) src;
      }
      {
        name = "colored-man-pages";
        inherit (pkgs.fishPlugins.colored-man-pages) src;
      }
      {
        name = "fifc";
        inherit (pkgs.fishPlugins.fifc) src;
      }
    ];

    functions = {
      fish_user_key_bindings = {
        body = ''
          # Execute this once per mode that emacs bindings should be used in
          fish_default_key_bindings -M insert

          # Then execute the vi-bindings so they take precedence when there's a conflict.
          # Without --no-erase fish_vi_key_bindings will default to
          # resetting all bindings.
          # The argument specifies the initial mode (insert, "default" or visual).
          fish_vi_key_bindings --no-erase insert
          bind --erase ctrl-n
          bind --mode insert ctrl-n 'down-or-search'
        '';
      };
    };

    shellInitLast = ''
      set -Ux fifc_editor nvim
      any-nix-shell fish --info-right | source
      zoxide init --cmd cd fish | source
      starship init fish | source
      enable_transience
    '';
  };
}
