{
  system.defaults = {
    # Disable the “Are you sure you want to open this application?” dialog
    LaunchServices.LSQuarantine = false;
    CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising = false;
  };

  # allow for using Touch ID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}
