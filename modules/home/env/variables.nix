{
  config,
  osConfig,
  ...
}:
let
  inherit (config.olympus.programs) defaults;
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
    FLAKE = osConfig.olympus.environment.flakePath;
    NH_FLAKE = osConfig.olympus.environment.flakePath;
    DO_NOT_TRACK = 1;
  };
}
