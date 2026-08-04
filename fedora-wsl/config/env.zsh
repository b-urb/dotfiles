# Shared login and interactive-shell environment.
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)
export PATH

export EDITOR=nvim
export VISUAL=nvim
export STARSHIP_CONFIG="$HOME/.config/fedora-wsl-dotfiles/starship.toml"
