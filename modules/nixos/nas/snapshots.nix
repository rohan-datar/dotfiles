_:
{
  flake.modules.nixos.nas-snapshots =
    _:
    {
      services.sanoid = {
        enable = true;
        datasets."data-pool/data-share" = {
          useTemplate = [ "production" ];
          recursive = true;
        };
        templates.production = {
          hourly = 36;
          daily = 30;
          monthly = 12;
          yearly = 0;
          autosnap = true;
          autoprune = true;
        };
      };
    };
}
