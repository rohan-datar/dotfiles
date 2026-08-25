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
      ghosttyPkg = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

      # Ghostty's fish shell integration (fish_handle_reflow for prompt
      # repaint after reflow/wake, OSC 133 prompt marks, cwd reporting).
      # --no-config skips vendor_conf.d where Ghostty normally injects this
      # locally, and plain ssh never sees Ghostty's env vars at all — so
      # remote prompts used to stay blank after the Mac's display woke.
      # Extract the script from the ghostty package itself instead of
      # vendoring it, so it always matches the packaged version. Only the
      # extracted text enters the closure, not the ghostty binary.
      ghosttyFishIntegration = pkgs.runCommand "ghostty-fish-integration.fish" { } ''
        f=
        for cand in \
          ${ghosttyPkg}/share/ghostty/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish \
          ${ghosttyPkg}/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
        do
          if [ -f "$cand" ]; then f="$cand"; break; fi
        done
        [ -n "$f" ] || { echo "ghostty fish integration not found in ${ghosttyPkg}" >&2; exit 1; }
        cp "$f" $out
      '';

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
          set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"
          starship init fish | source
          enable_transience
        end

        source ${ghosttyFishIntegration}
      '';
    };
}
