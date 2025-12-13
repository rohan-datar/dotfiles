{
  config,
  ...
}:
{
  programs.zed-editor = {
    inherit (config.olympus.aspects.graphical) enable;
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
      ui_font_size = 15;
      buffer_font_size = 15;
      load_direnv = "shell_hook";
      show_whitespaces = "all";
    };
  };
}
