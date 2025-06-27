{
  lib,
  pkgs,
  ...
}:
with lib; let
  build_stage = ''
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "NixOS Rebuilding.."
        nh os switch .
        current=$(nixos-rebuild list-generations | grep True | awk '{printf "%s %s %s %s, NixOs\n", $1, $2, $3, $5}')
        notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Nix Darwin Rebuilding..."
        nh darwin switch $NIX_FLAKE_LOCATION
        current=$(sudo darwin-rebuild --list-generations | grep current | awk '{printf " %s %s %s, MacOs\n", $1, $2, $3}')
    fi
        nh home switch .
  '';
  rebuild = ''
    pushd "$NIX_FLAKE_LOCATION"

    # Early return if no changes were detected
    if git diff --quiet; then
        echo "no changes detected, exiting."
    fi

    # Autoformat your nix files
    ${pkgs.alejandra} . &> /dev/null \
        || ( ${pkgs.alejandra} . ; echo "formatting failed" && exit 1)


    ${build_stage}

    # Shows your changes
    git --no-pager diff -U0

    # Commit all changes witih the generation metadata
    git commit -am "$current"

    # Back to where you were
    popd
  '';
  update = ''
    pushd "$NIX_FLAKE_LOCATION"
    git pull

    nix flake update

    ${build_stage}

    # Commit all changes witih the generation metadata
    git commit -am "$current"

    # Back to where you were
    popd
  '';

  rebuilder = pkgs.writeShellScriptBin "nxr" rebuild;
  updater = pkgs.writeShellScriptBin "nxu" update;
in {
  home.packages = [
    rebuilder
    updater
  ];
}
