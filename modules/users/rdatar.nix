{
  flake.modules.nixos.rdatar =
    { config, lib, ... }:
    let
      ifTheyExist = groups: lib.filter (group: lib.hasAttr group config.users.groups) groups;

      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYDkyHobLUDOAkNqHxcOkVScdCclKG6m6Az7OT/NAd3"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2wVTZEDwBCIvmTEiKj3pUmhOR+W9qknzbVTXhM25h6"
      ];

      # The Warpgate bastion's client keypair — one pair, shared across all of
      # its SSH targets.
      warpgateKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEQ7q2qoWj401UGyjxqAGPC0wxA5EKui6ZX3T9XzfUG"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDlZ9QRFRY3cgKU9Qf+ksqm8QfU+++8sOB8kVZbIHrJYMf9rCR5ij0blAsVWdNpv1QqJ2ZoI7TSfUgZqYxvZ1QsFy6Z00msdOvhZwtJierfMnpJT4aR1w/0FHgkOoKgl267b2UnokSv3TROvAUjy/ADme6S4byD/nA/CXgjcbBlwin6G2N9ljh/eWbTa9rmiN0gIDOljCrfbovv+/AJbr+LWSe+T9AOLzdg2OMdNbxvcybFYrwxgWWbOpp0fYPpS3MrU4wv0U60a2tLSmD0A9fRY2htkhDgcabolVgP6ApJgwcqZUHCiWKEdEDycr+tcjN0lApPDFSbCB3UuNdSjCYb2dSpCQBD0KY/2Vmn3Scahkb5Ha1zbajrIPv78ZWOK0BmLEbvlTAGf+z53m2+UedrlvqRNqtzr1n7+JoRS+oD7KqaSdhqOGKBlFTLVMP/wq89dW5L6HcrUSNejjGLiutKCtjbEs4m8COnuPuPtWwPK9+meZN3Ixj2B7V0jXICAdV+9DbgvVRzUplTLz7Nvw0M7taihoEwxU5TlGUzgliaoB2L3dhSZDB+fJ/8KEDJrjbvIa7yrvMNiItFpuLWsXsB/jI/055VGCeUg+bshDD47ll5dFM/8W+mxdQiYdTfMQg2g90HrYNWiKF4m5FSHwb6S9luB/gMDJErvsVuoFjNYQ=="
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
        openssh.authorizedKeys.keys = sshKeys ++ warpgateKeys;
      };

      users.users.root.openssh.authorizedKeys.keys = sshKeys;
    };
}
