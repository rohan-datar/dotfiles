{
  flake.modules.nixos.terminfo =
    { pkgs, ... }:
    {
      # put terminfo onto our servers so the ssh experience is better
      environment.systemPackages = [ pkgs.ghostty.terminfo ];
    };
}
