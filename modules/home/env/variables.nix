{
  config,
  osConfig,
  ...
}:
let
  inherit (config.olympus.programs) defaults;
  inherit (osConfig.olympus.environment) flakePath;
in
{
  home.sessionVariables = {
    EDITOR = defaults.editor;
    GIT_EDITOR = defaults.editor;
    VISUAL = defaults.editor;
    TERMINAL = defaults.terminal;
    SYSTEMD_PAGERSECURE = "true";
    PAGER = defaults.pager;
    MANPAGER = defaults.manpager;
    FLAKE = flakePath;
    NH_FLAKE = flakePath;
    DO_NOT_TRACK = 1;
  };
}
