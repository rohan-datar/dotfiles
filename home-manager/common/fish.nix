{...}: {
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

    shellAliases = {
      bat = "cat";
    };

    plugins = [
      pkgs.fishPlugins.macos
      pkgs.fishPlugins.sponge
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.colored-man-pages
    ];

    shellInit = ''
      set -g fish_key_bindings fish_vi_key_bindings
    '';
    shellInitLast = ''
      any-nix-shell fish --info-right | source
      zoxide init --cmd cd fish | source
      starship init fish | source
      enable_transience
    '';
  };
}
