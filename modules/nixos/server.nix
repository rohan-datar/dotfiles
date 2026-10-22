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
        inputs.ragenix.nixosModules.default
      ];

      services.openssh.enable = true;
      # Each host opens 22 on its LAN interface only; RoadWarrior WireGuard
      # clients arrive through the router on that interface.
      services.openssh.openFirewall = false;

      services.fail2ban.enable = true;

      environment.variables.EDITOR = "nvim";

      # see https://www.openwall.com/lists/oss-security/2025/12/28/4
      systemd.generators.systemd-ssh-generator = "/dev/null";
      systemd.sockets.sshd-unix-local.enable = lib.mkForce false;
      systemd.sockets.sshd-vsock.enable = lib.mkForce false;

      environment.systemPackages = [
        pkgs.gcc
        pkgs.curl
        pkgs.cifs-utils
        inputs.editorconfig.packages.${pkgs.stdenv.hostPlatform.system}.nvim-minimal
        # Server editors must not pull in workstation toolchains (notably TeX).
        inputs.editorconfig.packages.${pkgs.stdenv.hostPlatform.system}.helix-minimal
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
