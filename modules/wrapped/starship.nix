_: {
  flake.wrappers.starship =
    {
      wlib,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # Nix has no \u string escape; JSON does, so route through fromJSON.
      u = code: builtins.fromJSON "\"\\u${code}\"";
    in
    {
      imports = [ wlib.modules.default ];

      package = pkgs.starship;

      constructFiles.starshipConfig = {
        relPath = "starship.toml";
        # Only the overrides are rendered at eval time; the builder merges them
        # into the nerd-font-symbols preset shipped with the starship package.
        # Reading the preset at build time (not via builtins.readFile) keeps the
        # preset tracking pkgs.starship without vendoring and without IFD.
        content = builtins.toJSON {
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
            format = "[${u "f253"} $duration]($style)";
          };

          status = {
            disabled = false;
            format = "[$symbol $status]($style)";
            symbol = u "ea87";
            not_found_symbol = u "f412";
            not_executable_symbol = u "f4ae";
            sigint_symbol = u "e009";
            signal_symbol = u "e00a";
          };

          os = {
            disabled = false;
          };

          directory = {
            format = "[${u "f07c"} $path ]($style)[$read_only]($read_only_style)";
            style = "bold blue";
            read_only = " ${u "f0be"}";
          };

          shlvl = {
            disabled = false;
            format = "[$shlvl ]($style)";
          };

          direnv = {
            disabled = false;
          };
        };
        builder = ''
          ${pkgs.remarshal}/bin/toml2json \
            "${pkgs.starship}/share/starship/presets/nerd-font-symbols.toml" \
            > "$TMPDIR/preset.json"
          ${pkgs.jq}/bin/jq -s '(.[0] * .[1]) | del(."$schema")' \
            "$TMPDIR/preset.json" "$1" > "$TMPDIR/merged.json"
          ${pkgs.remarshal}/bin/json2toml "$TMPDIR/merged.json" "$2"
        '';
      };

      env.STARSHIP_CONFIG = config.constructFiles.starshipConfig.path;
    };
}
