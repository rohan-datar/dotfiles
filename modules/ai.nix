{ inputs, ... }:
let
  aiPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = builtins.attrValues {
        inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system})
          codex
          omp
          pi
          prime-agent
          ;
      };
    };
in
{
  flake.modules.nixos.ai = aiPackages;
  flake.modules.darwin.ai = aiPackages;
}
