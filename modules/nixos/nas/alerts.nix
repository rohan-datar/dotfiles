_: {
  # Mail transport (msmtp) comes from the shared `mail` aspect — this aspect
  # only decides what gets mailed and assumes sendmail/msmtp are present.
  flake.modules.nixos.nas-alerts =
    { pkgs, ... }:
    {
      # SMART pre-failure indicators: journal + email.
      services.smartd = {
        enable = true;
        notifications.mail = {
          enable = true;
          recipient = "me@rdatar.com";
          sender = "nas@rdatar.com";
        };
      };

      # ZED emails ZFS events (errors, resilvers, scrub results).
      # enableMail stays false: that option expects a mail(1)-style binary; calling
      # msmtp directly via ZED_EMAIL_PROG is the working pattern (NixOS wiki, ZFS page).
      services.zfs.zed = {
        enableMail = false;
        settings = {
          ZED_EMAIL_ADDR = [ "me@rdatar.com" ];
          ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
          ZED_EMAIL_OPTS = "@ADDRESS@";
          ZED_NOTIFY_INTERVAL_SECS = 3600;
          ZED_NOTIFY_VERBOSE = true; # also mail scrub completions, not just failures
        };
      };
    };
}
