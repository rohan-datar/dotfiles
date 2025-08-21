{
  system.defaults = {
    # use 12 hour time
    NSGlobalDomain.AppleICUForce24HourTime = false;

    menuExtraClock = {
      # show 12 hour clock
      Show24Hour = true;

      # show digital clock
      IsAnalog = false;

      # show AM/PM
      ShowAMPM = true;

      # show day of month
      ShowDayOfMonth = true;

      # show day of week
      ShowDayOfWeek = true;

      # show seconds
      ShowSeconds = false;
    };
  };
}
