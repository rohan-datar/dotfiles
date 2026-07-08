_: {
  flake.modules.darwin.brew =
    { inputs, lib, ... }:
    {
      imports = [
        inputs.homebrew.darwinModules.nix-homebrew
      ];

      config = {
        nix-homebrew = {
          enable = true;
          user = lib.mkDefault "rohandatar";
          enableRosetta = true;
          autoMigrate = true;
        };

        homebrew = {
          enable = true;
          brews = [
            "mas"
            "swift"
          ];
          casks = [
            "zen"
          ];
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };
      };
    };
}
