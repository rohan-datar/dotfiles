{ lib, ... }:
{
  options.flake.meta.defaults = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Flake-wide default programs (terminal, browser, editor, ...)";
  };

  config.flake.meta.defaults = {
    terminal = "ghostty";
    fileManager = "nautilus";
    browser = "zen";
    editor = "nvim";
    pager = "less -FR";
    manpager = "nvim --clean +Man!";
    launcher = "quickshell";
    bar = "quickshell";
    screenLocker = "noctalia";
  };
}
