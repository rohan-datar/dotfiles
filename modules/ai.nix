let
  aiPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = builtins.attrValues {
        inherit (pkgs.llm-agents)
          claude-code
          omp
          ;
      };
    };
in
{
  flake.modules.nixos.ai = aiPackages;
  flake.modules.darwin.ai = aiPackages;
}
