
#!/usr/bin/env bash

pushd ~/nix/

git pull

nix flake update

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "NixOS Rebuilding..."
  # Rebuild, output simplified errors, log trackebacks
  sudo nixos-rebuild switch --flake ~/nix#home-desktop
  # Get current generation metadata
  current=$(nixos-rebuild list-generations | grep current)
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Nix Darwin Rebuilding..."
  darwin-rebuild switch --flake ~/nix#macbook
  current=$(darwin-rebuild --list-generations | grep current)
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
