{
  config,
  ...
}:
{
  programs.zed-editor = {
    # inherit (config.olympus.aspects.graphical) enable;
    # https://github.com/NixOS/nixpkgs/issues/478546
    enable = true;
    extensions = [
      "nix"
      "rust"
      "go"
      "make"
      "swift"
      "superhtml"
    ];

    userSettings = {
      base_keymap = "Emacs";
      vim_mode = true;
      ui_font_family = "SFProDisplay Nerd Font";
      ui_font_size = 15;
      buffer_font_family = "Maple Mono NF";
      buffer_font_size = 15;
      load_direnv = "shell_hook";
      show_whitespaces = "all";
    };
  };
}
