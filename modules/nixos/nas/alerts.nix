_: {
  flake.modules.nixos.nas-alerts =
    { config, pkgs, ... }:
    {
      age.secrets.smtp-password.file = ../../../secrets/smtp-password.age;

      # Outbound mail via iCloud SMTP (see Apple support 102525). Auth uses an
      # app-specific password stored in agenix; regular Apple ID passwords are rejected.
      programs.msmtp = {
        enable = true;
        setSendmail = true; # provides /run/wrappers/bin/sendmail (used by smartd)
        accounts.default = {
          auth = true;
          host = "smtp.mail.me.com";
          port = 587;
          tls = true;
          tls_starttls = true;
          # iCloud wants the account's primary address as the username; the custom-domain
          # address works as From once it's an alias on the account.
          user = "rohandatar@icloud.com";
          from = "nas@rdatar.com";
          # Absolute path required: passwordeval runs inside arbitrary service
          # contexts (smartd's unit has no coreutils in PATH, so bare `cat` fails).
          passwordeval = "${pkgs.uutils-coreutils-noprefix}/bin/cat ${config.age.secrets.smtp-password.path}";
        };
      };

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
