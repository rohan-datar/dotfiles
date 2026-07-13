{ inputs, ... }:
let
  aiPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = builtins.attrValues {
        inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system})
          claude-code
          omp
          pi
          ;
      };
    };
in
{
  flake.modules.nixos.ai = aiPackages;
  flake.modules.darwin.ai = aiPackages;
}
