{
  lib,
  self,
  _class,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    mergeAttrsList
    optionalAttrs
    genAttrs
    filter
    hasAttr
    ;

  ifTheyExist = config: groups: filter (group: hasAttr group config.users.groups) groups;
in
{

  users.users = genAttrs config.olympus.system.users (
    name:
    let
      inherit (config.home-manager.users.${name}.olympus.programs.defaults) shell;
    in
    mergeAttrsList [
      {
        shell = "/run/current-system/sw/bin/${shell}";
      }

      (optionalAttrs (_class == "darwin") {
        home = "/Users/${name}";
      })

      (optionalAttrs (_class == "nixos") {
        home = "/home/${name}";

        uid = mkDefault 1000;
        isNormalUser = true;

        # only add groups that exist
        extraGroups = [
          "wheel"
          "nix"
        ]
        ++ ifTheyExist config [
          "network"
          "networkmanager"
          "systemd-journal"
          "audio"
          "pipewire" # this give us access to the rt limits
          "video"
          "input"
          "power"
          "wireshark"
          "docker"
          "podman"
          "git"
          "libvirtd"
        ];
      })
    ]
  );
}
