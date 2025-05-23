#!/usr/bin/env bash

pushd ~/nix/

# Early return if no changes were detected
if git diff --quiet '*.nix'; then
    echo "no changes detected, exiting."
    popd
    exit 0
fi

# Autoformat your nix files
alejandra . &>/dev/null \
  || ( alejandra . ; echo "formatting failed!" && exit 1)

# Shows your changes
git diff -U0 '*.nix'

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "NixOS Rebuilding..."
  # Rebuild, output simplified errors, log trackebacks
  sudo nixos-rebuild switch --flake ~/nix#home-desktop
  # Get current generation metadata
  current=$(nixos-rebuild list-generations | grep current)
  home-manager switch --flake ~/nix#rdatar
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Nix Darwin Rebuilding..."
  sudo darwin-rebuild switch --flake ~/nix#macbook
  current=$(sudo darwin-rebuild --list-generations | grep current)
  home-manager switch --flake ~/nix#rohandatar
else
  echo "$OSTYPE not supported"
  exit 1
fi



# Commit all changes witih the generation metadata
git commit -am "$current"

# Back to where you were
popd

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
# Notify all OK!
notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available
fi
