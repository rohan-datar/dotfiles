let
  # The persistent albedo VM's own SSH identity (generated in the guest 2026-11-22).
  # Owner decision: albedo may use the owner's account on the workstations only. Never add
  # this key to rdatar.nix's shared list, which is also root's on every server.
  pallasKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGX9r/aBfkor0VB1lO6OhbTGK/fkf2CA7YetE7pnRmvg albedo@pallas";
in
{
  flake.modules.nixos.pallas-access = {
    users.users.rdatar.openssh.authorizedKeys.keys = [ pallasKey ];
  };
  flake.modules.darwin.pallas-access = {
    users.users.rohandatar.openssh.authorizedKeys.keys = [ pallasKey ];
  };
}
