_: {
  # SMART pre-failure indicators: journal + email. Hosts opt in and provide
  # their own device list/transport flags; mail transport comes from `mail`.
  flake.modules.nixos.smart-alerts = _: {
    services.smartd = {
      enable = true;
      notifications.mail = {
        enable = true;
        recipient = "me@rdatar.com";
        sender = "homelab@rdatar.com";
      };
    };
  };
}
