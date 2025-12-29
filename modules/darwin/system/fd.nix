{
  # Increase system-wide file descriptor limits for macOS
  # This fixes "Too many open files" errors during nix operations
  launchd.daemons.limit-maxfiles = {
    serviceConfig = {
      Label = "limit.maxfiles";
      ProgramArguments = [
        "launchctl"
        "limit"
        "maxfiles"
        "64000"
        "524288"
      ];
      RunAtLoad = true;
    };
  };
}
