#!/usr/bin/env sh

# Dotfiles feature flags (tracked defaults)

# Terminal multiplexer mode:
#   DOTFILES_ZELLIJ_MODE=native  -> WezTerm-native mode
#   DOTFILES_ZELLIJ_MODE=full    -> Full zellij mode (autostart + zellij keybind mode)
#   DOTFILES_ZELLIJ_MODE=bridge  -> Per-WezTerm-pane isolated zellij bridge (plain UI)
export DOTFILES_ZELLIJ_MODE=native

# Legacy fallback toggle (used only when DOTFILES_ZELLIJ_MODE is unset):
#   0/false/no/off  -> native
#   1/true/yes/on   -> full
export DOTFILES_ENABLE_ZELLIJ=0

# WezTerm custom event handlers (tab title/right status/etc)
# Disabled by default to preserve built-in tab rename behavior.
export DOTFILES_WEZTERM_DISABLE_EVENTS=1

# Optional overrides:
# export WM_FORCE_DISPLAY_SERVER=wayland
# export DOTFILES_DISABLE_BITWARDEN_SSH_AGENT=1
