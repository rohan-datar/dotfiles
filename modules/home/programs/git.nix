_: {
  programs.git = {
    enable = true;
    userEmail = "me@rohandatar.com";
    userName = "Rohan Datar";

    attributes = [
      "* text=auto"
    ];

    aliases = {
      diff = "diff --word-diff";
      blame = "blame -C -C -C";
    };

    extraConfig = {
      merge = {
        conflictstyle = "diff3";
      };

      rerere = {
        enabled = "true";
      };
    };
  };
}
