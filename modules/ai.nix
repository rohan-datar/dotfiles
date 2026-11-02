{ inputs, ... }:
let
  aiPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = builtins.attrValues {
        inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system})
          omp
          prime-agent
          antigravity-hub
          ;
        inherit (inputs.albedo.packages.${pkgs.stdenv.hostPlatform.system}) albedo;
      };
    };
in
{
  flake.modules.nixos.ai = aiPackages;
  flake.modules.darwin.ai = aiPackages;
}
