{ self, ... }:
{
  flake.modules.nixos.default =
    { config, ... }:
    {
      imports = [
        self.modules.nixos.command-not-found
        self.modules.nixos.console
        self.modules.nixos.documentation
        self.modules.nixos.extras
        self.modules.nixos.firmware
        self.modules.nixos.localization
        self.modules.nixos.nix
        self.modules.nixos.oomd
        self.modules.nixos.packages
        self.modules.nixos.serial
        self.modules.nixos.shell
        self.modules.nixos.size
        self.modules.nixos.terminfo
        self.modules.nixos.time
      ];

      # Remove once nixpkgs cacert drops this compromised root.
      security.pki.caCertificateBlacklist = [ "emSign ECC Root CA - G3" ];

      # nixpkgs certifi 2026.07.22 still trusts emSign ECC Root CA - G3 in its own
      # cacert.pem. Its env.patch makes certifi.where() honour NIX_SSL_CERT_FILE,
      # so point services and shells at the system bundle, which rejects G3.
      # Remove once nixpkgs ships certifi >= 2026.10.19 (GHSA-6q48-6c7w-9gw2).
      systemd.globalEnvironment.NIX_SSL_CERT_FILE = config.security.pki.caBundle;
      environment.variables.NIX_SSL_CERT_FILE = config.security.pki.caBundle;
    };
}
