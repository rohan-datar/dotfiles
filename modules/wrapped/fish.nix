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
        # --no-config disables history by setting fish_history to an invalid
        # session name ("||") and enabling fish_private_mode; undo both so
        # history persists across sessions. Side effect: `fish --private` on
        # the wrapped fish needs fish_private_mode re-set manually.
        set -e fish_private_mode
        set -g fish_history fish

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

          # --no-config leaves fish_complete_path empty, dropping completions
          # shipped by nix-installed packages. Built-in completions still work
          # via fish's internal fallback, so only the vendor dirs are needed.
          for profile in ~/.nix-profile /etc/profiles/per-user/$USER /run/current-system/sw /nix/var/nix/profiles/default
            test -d $profile/share/fish/vendor_completions.d
            and set -a fish_complete_path $profile/share/fish/vendor_completions.d
          end

          command -q carapace; and carapace _carapace fish | source

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
