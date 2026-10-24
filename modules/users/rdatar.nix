{
  flake.modules.nixos.rdatar =
    { config, lib, ... }:
    let
      ifTheyExist = groups: lib.filter (group: lib.hasAttr group config.users.groups) groups;

      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYDkyHobLUDOAkNqHxcOkVScdCclKG6m6Az7OT/NAd3"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2wVTZEDwBCIvmTEiKj3pUmhOR+W9qknzbVTXhM25h6"
      ];
    in
    {
      users.users.rdatar = {
        shell = "/run/current-system/sw/bin/bash";
        home = "/home/rdatar";
        uid = lib.mkDefault 1000;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "nix"
        ]
        ++ ifTheyExist [
          "network"
          "networkmanager"
          "systemd-journal"
          "audio"
          "pipewire"
          "video"
          "input"
          "power"
          "wireshark"
          "docker"
          "podman"
          "git"
          "libvirtd"
        ];
        openssh.authorizedKeys.keys = sshKeys;
      };

      users.users.root.openssh.authorizedKeys.keys = sshKeys;
    };
}
