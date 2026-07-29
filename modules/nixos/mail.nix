_: {
  # Shared outbound mail via iCloud SMTP (see Apple support 102525), split out of
  # nas-alerts so home-controller's backup failure hooks can send too. Auth uses an
  # app-specific password stored in ragenix; regular Apple ID passwords are rejected.
  #
  # From stays nas@rdatar.com on every host: iCloud rejects senders that aren't the
  # account's primary address or a verified alias, and nas@ is the alias known to
  # work. Switching to a host-neutral homelab@ needs that alias verified first.
  flake.modules.nixos.mail =
    { config, pkgs, ... }:
    {
      age.secrets.smtp-password.file = ../../secrets/smtp-password.age;

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

      # Generic failed-unit mailer, instantiated via
      # `OnFailure = [ "backup-failure-email@%n.service" ]` on the unit to watch.
      # Lives here rather than in each restic aspect so both hosts share one copy.
      systemd.services."backup-failure-email@" = {
        serviceConfig.Type = "oneshot";
        scriptArgs = "%i";
        script = ''
          ${pkgs.msmtp}/bin/msmtp me@rdatar.com <<EOF
          Subject: [$(${pkgs.uutils-coreutils-noprefix}/bin/uname -n)] backup unit $1 FAILED

          journalctl -u $1 -e on the host for details.
          EOF
        '';
      };
    };
}
