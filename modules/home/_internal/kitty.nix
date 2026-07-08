_: {
  flake.modules.homeManager.kitty = { pkgs, ... }: {
    programs.kitty = {
      enable = true;
      font = {
        name = pkgs.lib.mkForce "Maple Mono NF";
        size = pkgs.lib.mkForce 14;
      };
    };
  };
}
