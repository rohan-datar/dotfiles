_: {
  flake.modules.darwin.extras =
    { inputs, ... }:
    {
      imports = [
        inputs.agenix.darwinModules.default
      ];

      # Expose `services.paneru` to home-manager on darwin (macOS only).
      home-manager.sharedModules = [
        inputs.paneru.homeModules.paneru
      ];
    };
}
