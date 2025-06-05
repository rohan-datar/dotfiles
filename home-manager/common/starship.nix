{
  pkgs,
  lib,
  ...
}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableTransience = true;

    presets = ["nerd-font-symbols"];

    settings = {
      add_newline = true;
      scan_timeout = 10;

      format = lib.concatStrings [
        "╭─ "
        "$os"
        "$all"
        "$line_break"
        "╰─"
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
        format = "[ $path ]($style)[$read_only ]($read_only_style)";
        style = "bold blue";
        read_only = " 󰌾";
      };
    };
  };
}
