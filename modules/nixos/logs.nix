{
  flake.modules.nixos.logs = {
    # limit systemd journal size
    # https://wiki.archlinux.org/title/Systemd/Journal#Persistent_journals
    services.journald.settings.Journal = {
      SystemMaxFileSize = "50M";
      SystemMaxUse = "100M";
      RuntimeMaxUse = "50M";
    };
  };
}
