{ inputs, ... }:
{
  flake.wrappers.fish =
    {
      wlib,
      pkgs,
      lib,
      ...
    }:
    let
      # catppuccin/nix exposes each port as a package; a fish .theme file is
      # just "variable value" lines, so turn it into set statements we can
      # source without needing a mutable ~/.config/fish/themes dir.
      catppuccinTheme = pkgs.runCommand "catppuccin-mocha.fish" { } ''
        sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' -e 's/^/set -g /' \
          ${
            inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.fish
          }/static/catppuccin-mocha.theme > $out
      '';
    in
    {
      imports = [ wlib.wrapperModules.fish ];

      # The upstream module defaults to --no-config, which also disables
      # reading/writing history; drop it so history persists across sessions.
      flags."--no-config" = false;

      abbreviations = {
        lg = "lazygit";
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
        pkgs.fishPlugins.macos
        pkgs.fishPlugins.colored-man-pages
      ];

      # configFile.content is sourced via --init-command on every fish startup
      # (interactive and non-interactive). Guard interactive-only init with
      # `status is-interactive`. Tools are resolved from PATH — the wrapped
      # versions are installed via environment.systemPackages (base.nix).
      configFile.content = ''
        # Key bindings
        function fish_user_key_bindings
          # Execute this once per mode that emacs bindings should be used in
          fish_default_key_bindings -M insert

          # Then execute the vi-bindings so they take precedence when there's a conflict.
          # Without --no-erase fish_vi_key_bindings will default to
          # resetting all bindings.
          # The argument specifies the initial mode (insert, "default" or visual).
          fish_vi_key_bindings --no-erase insert
          bind --erase ctrl-n
          bind --mode insert ctrl-n 'down-or-search'
        end

        set -Ux fifc_editor nvim

        if status is-interactive
          set fish_greeting

          # Catppuccin Mocha syntax highlighting + pager colors
          source ${catppuccinTheme}

          any-nix-shell fish --info-right | source
          zoxide init --cmd cd fish | source
          direnv hook fish | source
          fzf --fish | source
          starship init fish | source
          enable_transience
        end
      '';
    };
}
