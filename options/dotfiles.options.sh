#!/usr/bin/env sh

# Dotfiles feature flags (tracked defaults)

# Terminal multiplexer mode:
#   0/false/no/off  -> WezTerm-native mode (default)
#   1/true/yes/on   -> Enable zellij autostart + zellij keybind mode
export DOTFILES_ENABLE_ZELLIJ=0

# WezTerm custom event handlers (tab title/right status/etc)
# Disabled by default to preserve built-in tab rename behavior.
export DOTFILES_WEZTERM_DISABLE_EVENTS=1

# Optional overrides:
# export WM_FORCE_DISPLAY_SERVER=wayland
# export DOTFILES_DISABLE_BITWARDEN_SSH_AGENT=1
