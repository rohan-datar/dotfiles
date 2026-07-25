_: {
  flake.modules.homeManager.nix = { config, ... }: {
    age.identityPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519"
      "${config.home.homeDirectory}/.ssh/id_rsa"
    ];

    age.secretsDir = "${config.home.homeDirectory}/.ragenix";
    age.secretsMountPoint = "${config.home.homeDirectory}/.ragenix.d";

    age.secrets.nix-access-tokens = {
      file = ../../../secrets/nix-access-tokens.conf.age;
    };

    nix.extraOptions = ''
      !include ${config.age.secrets.nix-access-tokens.path}
    '';
  };
}
