{ config, ... }:
{
  age.identityPaths = [
    "${config.home.homeDirectory}/.ssh/id_ed25519"
    "${config.home.homeDirectory}/.ssh/id_rsa"
  ];

  # Use fixed paths to avoid dynamic $(getconf DARWIN_USER_TEMP_DIR) which breaks !include
  age.secretsDir = "${config.home.homeDirectory}/.agenix";
  age.secretsMountPoint = "${config.home.homeDirectory}/.agenix.d";

  age.secrets.nix-access-tokens = {
    file = ../../secrets/nix-access-tokens.conf.age;
  };

  nix = {
    extraOptions = ''
      !include ${config.age.secrets.nix-access-tokens.path}
    '';
  };
}
