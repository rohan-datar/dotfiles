{ inputs', ... }:
let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYDkyHobLUDOAkNqHxcOkVScdCclKG6m6Az7OT/NAd3"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2wVTZEDwBCIvmTEiKj3pUmhOR+W9qknzbVTXhM25h6"
  ];
in
{

  users.users = {
    rdatar = {
      isNormalUser = true;
      description = "Rohan Datar";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      openssh.authorizedKeys.keys = sshKeys;
    };

    root = {
      openssh.authorizedKeys.keys = sshKeys;
    };
  };

  home-manager.users.rdatar = {
    programs = {
      bat.enable = true;
      carapace.enable = true;
      fish.enable = true;
      fzf.enable = true;
      starship.enable = true;
      tmux.enable = true;
      neovim.enable = true;
    };
  };
}
