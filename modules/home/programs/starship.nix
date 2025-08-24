{
  pkgs,
  lib,
  ...
}:
{
  programs.starship =
    let
      getPreset =
        name:
        (
          with builtins;
          removeAttrs (fromTOML (readFile "${pkgs.starship}/share/starship/presets/${name}.toml")) [
            "\"$schema\""
          ]
        );
    in
    {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableTransience = true;
      enableInteractive = true;

      settings =
        lib.recursiveUpdate
          (lib.mergeAttrsList [
            (getPreset "nerd-font-symbols")
          ])
          {
            add_newline = true;
            scan_timeout = 10;

            format = lib.concatStrings [
              "$os "
              "$all"
              "$line_break"
              "$character"
            ];

            right_format = lib.concatStrings [
              "$status"
              " "
              "$cmd_duration"
            ];

            cmd_duration = {
              format = "[ $duration]($style)";
            };

            status = {
              disabled = false;
              format = "[$symbol $status]($style)";
              symbol = "";
              not_found_symbol = "";
              not_executable_symbol = "";
              sigint_symbol = "";
              signal_symbol = "";
            };

            os = {
              disabled = false;
            };

            directory = {
              format = "[ $path ]($style)[$read_only]($read_only_style)";
              style = "bold blue";
              read_only = " 󰌾";
            };

            shlvl = {
              disabled = false;
              format = "[$shlvl ]($style)";
            };

            direnv = {
              disabled = false;
            };
          };
    };
}
