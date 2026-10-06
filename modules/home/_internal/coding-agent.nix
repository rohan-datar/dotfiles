{
  flake.modules.homeManager.coding-agent = {
    home.file.".prime/agent/extensions/neuralwatt/index.ts".source = ./coding-agent/neuralwatt.ts;
    home.file.".omp/agent/extensions/neuralwatt/index.ts".source = ./coding-agent/neuralwatt.ts;
  };
}
