# OS/Distro Detection and Environment Setup
# This must be sourced first in all zsh configurations

# Detect OS
export DOTFILES_OS=""
export DOTFILES_DISTRO=""

# Use OSTYPE for primary detection (more reliable than uname)
case "$OSTYPE" in
    darwin*)
        DOTFILES_OS="darwin"
        DOTFILES_DISTRO="macos"
        ;;
    linux*)
        DOTFILES_OS="linux"
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    DOTFILES_DISTRO="ubuntu"
                    ;;
                arch|manjaro)
                    DOTFILES_DISTRO="arch"
                    ;;
                *)
                    DOTFILES_DISTRO="unknown"
                    ;;
            esac
        else
            DOTFILES_DISTRO="unknown"
        fi
        ;;
    *)
        DOTFILES_OS="unknown"
        DOTFILES_DISTRO="unknown"
        ;;
esac

# Helper functions
is_macos() { [ "$DOTFILES_OS" = "darwin" ]; }
is_linux() { [ "$DOTFILES_OS" = "linux" ]; }
is_ubuntu() { [ "$DOTFILES_DISTRO" = "ubuntu" ]; }
is_arch() { [ "$DOTFILES_DISTRO" = "arch" ]; }

# Export functions for use in subshells
export -f is_macos is_linux is_ubuntu is_arch
