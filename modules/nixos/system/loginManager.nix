{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;

  greeterNiriConfig = pkgs.writeText "greeter-niri-config.kdl" ''
    spawn-at-startup "${getExe config.programs.regreet.package}"

    // Quit niri after regreet exits (user logged in or greeter closed)
    spawn-at-startup "sh" "-c" "sleep 1 && ${getExe pkgs.niri} msg action quit --skip-confirmation"

    input {
      keyboard {
        numlock
      }
    }

    cursor {
      xcursor-theme "catppuccin-mocha-dark-cursors"
      xcursor-size 24
    }

    hotkey-overlay {
      skip-at-startup
    }
  '';
in
{
  config = mkIf config.olympus.aspects.graphical.enable {
    # services.displayManager.sddm = {
    #   enable = true;
    #   package = pkgs.kdePackages.sddm;
    #   autoNumlock = true;
    #   wayland.enable = true;
    # };

    programs.regreet = {
      enable = true;

      theme = {
        package = pkgs.magnetic-catppuccin-gtk;
        name = "Catppuccin-GTK-Dark";
      };

      cursorTheme = {
        package = pkgs.catppuccin-cursors.mochaDark;
        name = "catppuccin-mocha-dark-cursors";
      };

      iconTheme = {
        package = pkgs.catppuccin-papirus-folders;
        name = "Papirus-Dark";
      };

      font = {
        name = "Inter";
        size = 14;
        package = pkgs.inter;
      };

      extraCss = ''
        window {
          background-color: #1e1e2e;
        }
      '';
    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${getExe pkgs.niri} -c ${greeterNiriConfig}";
        user = "greeter";
      };
    };
  };
}
