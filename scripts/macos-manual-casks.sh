#!/usr/bin/env bash
set -euo pipefail

# Manual casks that may need password / GUI permissions
casks=(
  tailscale-app
  sf-symbols
  elgato-stream-deck
  font-sf-mono
  font-sf-pro
)

for cask in "${casks[@]}"; do
  echo "==> Installing $cask"
  brew install --cask "$cask" || true
done

echo "Done."
