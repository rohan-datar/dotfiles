{
  age.identityPaths = [
    "/Users/rohandatar/.ssh/id_ed25519"
    "/Users/rohandatar/.ssh/id_rsa"
  ];

  nix = {
    enable = true;
    # nix gc works slightly differently on darwin, so we need to adjust the
    # interval such that it works properly here.
    gc.interval = {
      Hour = 3;
      Minute = 15;
    };

    settings.extra-platforms = [
      "aarch64-darwin"
      "x86-64-darwin"
    ];
  };
}
