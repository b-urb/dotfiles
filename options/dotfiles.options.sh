#!/usr/bin/env sh

# Dotfiles feature flags (tracked defaults)

# Terminal multiplexer mode:
#   0/false/no/off  -> WezTerm-native mode (default)
#   1/true/yes/on   -> Enable zellij autostart + zellij keybind mode
export DOTFILES_ENABLE_ZELLIJ=0

# Optional overrides:
# export WM_FORCE_DISPLAY_SERVER=wayland
# export DOTFILES_DISABLE_BITWARDEN_SSH_AGENT=1
