{
  lib,
  config,
  _class,
  ...
}:
let
  inherit (lib) mkOption mergeAttrsList optionalAttrs;
  inherit (lib.types) attrsOf package;
in
{
  options.olympus.packages = mkOption {
    type = attrsOf package;
    default = { };
    description = "A set of packages to be installed by olympus environment.";
  };

  config = mergeAttrsList [
    (optionalAttrs (_class == "nixos" || _class == "darwin") {
      environment.systemPackages = builtins.attrValues config.olympus.packages;
    })

    (optionalAttrs (_class == "homeManager") {
      home.packages = builtins.attrValues config.olympus.packages;
    })
  ];
}
}
