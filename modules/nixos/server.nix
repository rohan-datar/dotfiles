{ inputs, config, ... }:
let
  wrapperModules = config.flake.wrapperModules;
in
{
  flake.modules.nixos.server =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.agenix.nixosModules.default
      ];

      services.openssh.enable = true;

      environment.variables.EDITOR = "nvim";

      # see https://www.openwall.com/lists/oss-security/2025/12/28/4
      systemd.generators.systemd-ssh-generator = "/dev/null";
      systemd.sockets.sshd-unix-local.enable = lib.mkForce false;
      systemd.sockets.sshd-vsock.enable = lib.mkForce false;

      environment.systemPackages = [
        pkgs.gcc
        pkgs.curl
        pkgs.cifs-utils
        pkgs.nh
        inputs.editorconfig.packages.${pkgs.stdenv.hostPlatform.system}.nvim-minimal
        # direnv is not in base.nix (graphical hosts get it via home-manager).
        # Servers install the wrapped version here.
        (lib.hiPrio (
          inputs.nix-wrapper-modules.lib.wrapPackage [
            wrapperModules.direnv
            { inherit pkgs; }
          ]
        ))
      ];
    };
}
