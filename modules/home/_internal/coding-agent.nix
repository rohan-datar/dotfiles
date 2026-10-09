_: {
  flake.modules.homeManager.coding-agent =
    { pkgs, ... }:
    let
      roles = import ./coding-agent/models.nix;

      yaml = pkgs.formats.yaml { };

      ompConfig = yaml.generate "omp-managed.yml" {
        # Custom semantic roles.
        modelRoles = roles // {
          task = "@worker";
          smol = "@scout";

          # Keep architecture as primary
          # Only choose pricier models manually
          plan = "@primary";
          slow = "@primary";

          advisor = "@reviewer";

          # Cheap utility work.
          tiny = "@utility";
          memory = "@utility";
          commit = "@utility";
        };

        eval = {
          py = true;
          js = true;
          tools.enabled = true;
          autoProvision = true;
        };

        python.kernelMode = "session";

        providers.openai-codex = {
          # When supported by the active Codex model, make eval the main
          # orchestration surface rather than exposing a wide direct tool menu.
          codeMode = "auto";
          codeModeDirectTools = [ ];
        };

        task = {
          # Strong persistent routing for bundled workers.
          agentModelOverrides = {
            scout = "@scout";
            sonic = "@scout";
            task = "@worker";
            reviewer = "@reviewer";
            security-reviewer = "@reviewer";
          };

          maxRecursionDepth = 2;
          maxConcurrency = 3;
          enableEffort = false;
          softRequestBudget = 40;
          softRequestBudgetNotice = true;
          maxRuntimeMs = 900000;
          speculativeLaunch = false;
        };

        magicKeywords = {
          enabled = true;
          workflow = true;
        };
      };

    in
    {
      home.sessionVariables.PI_CONFIG_FILES = toString ompConfig;
      home.file.".omp/agent/RULES.md".source = ./coding-agent/RULES.md;
      home.file.".prime/agent/extensions/neuralwatt/index.ts".source = ./coding-agent/neuralwatt.ts;
    };
}
