{
  flake.modules.nixos.printing = {
    services = {
      printing = {
        enable = true;
      };

      # required for network discovery of printers
      avahi = {
        enable = true;
        nssmdns4 = true;
        nssmdns6 = true;
        openFirewall = true;
      };
    };
  };
}
