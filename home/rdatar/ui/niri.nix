{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    programs.niri = {
      settings = {
        binds = {
          "Mod+Space".action.spawn = [
            "qs"
            "-c"
            "noctalia-shell"
            "ipc"
            "call"
            "launcher"
            "toggle"
          ];

          "Mod+Return".action.spawn = "ghostty";
          "Mod+B".action.spawn = "zen";

          "XF86AudioRaiseVolume".action.spawn = [
            "qs"
            "-c"
            "noctalia-shell"
            "ipc"
            "call"
            "volume"
            "increase"
          ];
          "XF86AudioLowerVolume".action.spawn = [
            "qs"
            "-c"
            "noctalia-shell"
            "ipc"
            "call"
            "volume"
            "decrease"
          ];
          "XF86AudioMute".action.spawn = [
            "qs"
            "-c"
            "noctalia-shell"
            "ipc"
            "call"
            "volume"
            "muteOutput"
          ];

          "XF86MonBrightnessUp".action.spawn = [
            "qs"
            "-c"
            "noctalia-shell"
            "ipc"
            "call"
            "brightness"
            "increase"
          ];

          "XF86MonBrightnessDown".action.spawn = [
            "qs"
            "-c"
            "noctalia-shell"
            "ipc"
            "call"
            "brightness"
            "decrease"
          ];
        };

        input.focus-follows-mouse.enable = true;
      };
    };
  };
}
