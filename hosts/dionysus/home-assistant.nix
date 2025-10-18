{
  networking = {
    enableIPv6 = true;
    firewall.allowedTCPPorts = [
      8123
      5580
      5540
      5541
    ];
    firewall.allowedUDPPorts = [
      5353
      5540
      5541
    ];
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [
        "/home/rdatar/HomeAssistant:/config"
        "/run/dbus:/run/dbus:ro"
      ];
      environment.TZ = "America/Chicago";
      # Note: The image will not be updated on rebuilds, unless the version label changes
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [
        # Use the host network namespace for all sockets
        "--network=host"
        # Pass devices into the container, so Home Assistant can discover and make use of them
        # "--device=/dev/ttyACM0:/dev/ttyACM0"
        "--privileged"
      ];
    };

    containers.matter-server = {
      volumes = [
        "/home/rdatar/matter-server:/data"
        "/run/dbus:/run/dbus:ro"
      ];
      image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
      environment.TZ = "America/Chicago";
      extraOptions = [
        "--network=host"
        "--privileged"
      ];
    };
  };
}
