{
  lib,
  pkgs,
  ...
}:
with lib;
let
  build_stage = ''
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "NixOS Rebuilding.."
        nh os switch .
        current=$(nh os info | grep current | awk -v date="$(date +"%y/%m/%d %H:%M:%S")" '{printf " %s %s: NixOS\n", $1, date}')
        notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Nix Darwin Rebuilding..."
        nh darwin switch .
        current=$(nh os info | grep current | awk -v date="$(date +"%y/%m/%d %H:%M:%S")" '{printf " %s %s: MacOs\n", $1, date}')
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
    ${pkgs.alejandra}/bin/alejandra . &> /dev/null \
        || ( ${pkgs.alejandra}/bin/alejandra . ; echo "formatting failed" && exit 1)


    ${build_stage}

    # Shows your changes
    git --no-pager diff -U0

    # Commit all changes witih the generation metadata
    git commit -am "$current"

  '';
  update = ''
    pushd "$NIX_FLAKE_LOCATION"
    git pull

    nix flake update

    ${build_stage}

    # Commit all changes witih the generation metadata
    git commit -am "$current"

  '';

  rebuilder = pkgs.writeShellScriptBin "nxr" rebuild;
  updater = pkgs.writeShellScriptBin "nxu" update;
in
{
  home.packages = [
    rebuilder
    updater
  ];
}
