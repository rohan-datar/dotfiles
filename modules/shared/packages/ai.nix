{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.olympus.aspects;
  aipkgs = pkgs.llm-agents;
in
{
  config = lib.mkIf cfg.graphical.enable {
    olympus.packages = {
      inherit (aipkgs)
        claude-code
        omp
        ;
    };
  };
}
