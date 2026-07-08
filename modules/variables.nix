let
  variables = {
    environment.variables = {
      SYSTEMD_PAGERSECURE = "true";
    };
  };
in
{
  flake.modules.nixos.variables = variables;
  flake.modules.darwin.variables = variables;
}
