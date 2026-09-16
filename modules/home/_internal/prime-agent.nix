{
  flake.modules.homeManager.prime-agent = {
    home.file.".prime/agent/extensions/neuralwatt/index.ts".source = ./prime-agent/neuralwatt.ts;
  };
}
