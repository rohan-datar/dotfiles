{pkgs, ...}: let
  catppuccin-fish = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "6a85af2ff722ad0f9fbc8424ea0a5c454661dfed";
    hash = "sha256-Oc0emnIUI4LV7QJLs4B2/FQtCFewRFVp7EDv8GawFsA=";
  };
in {
  xdg.configFile."fish/themes/Catppuccin Mocha.theme".source = "${catppuccin-fish}/themes/Catppuccin Mocha.theme";
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    generateCompletions = true;
    preferAbbrs = true;

    shellAbbrs = {
      lg = "lazygit";
      gbc = "sudo nix-collect-garbage --delete-older-than 30d && nix-collect-garbage --delete-older-than 30d";

      # ls aliases
      ls = "ls --color";
      lsa = "ls -lah";
      l = "ls -lah";
      ll = "ls -lh";
      la = "ls -lAH";
    };

    plugins = [
      {
        name = "macos";
        src = pkgs.fishPlugins.macos.src;
      }
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf.src;
      }
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }
      {
        name = "fifc";
        src = pkgs.fishPlugins.fifc.src;
      }
    ];

    functions = {
      fish_user_key_bindings = {
        body = ''
          # Execute this once per mode that emacs bindings should be used in

          # Then execute the vi-bindings so they take precedence when there's a conflict.
          # Without --no-erase fish_vi_key_bindings will default to
          # resetting all bindings.
          # The argument specifies the initial mode (insert, "default" or visual).
          fish_vi_key_bindings --no-erase insert
        '';
      };
    };

    shellInitLast = ''
      any-nix-shell fish --info-right | source
      zoxide init --cmd cd fish | source
      starship init fish | source
      enable_transience
    '';
  };
}
