# Environment Variables

# Editor configuration
export EDITOR=nvim
export ZVM_VI_EDITOR=nvim
export K9S_EDITOR=nvim

# Common paths
export PATH=$PATH:$HOME/.pulumi/bin
export PATH=$PATH:$HOME/.rustup
export PATH=$PATH:$HOME/.cargo
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/Tools

# Development settings
export CGO_ENABLED=1
export GODEBUG='netdns=cgo'
export GOPRIVATE="dev.azure.com"

# OS-specific exports
if is_macos; then
    export PATH="/opt/homebrew/opt/go@1.21/bin:$PATH"
    export DYLD_FALLBACK_LIBRARY_PATH="$(xcode-select --print-path)/Toolchains/XcodeDefault.xctoolchain/usr/lib/"
    export LDFLAGS=-L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
    export PICO_SDK_PATH="$HOME/Private/Development/embedded/pico-sdk"

    # Conda for macOS (Homebrew-installed)
    __conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/homebrew/anaconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup

    # Deno
    [ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

elif is_linux; then
    # Linux-specific conda paths (if needed)
    if [ -d "$HOME/anaconda3" ]; then
        __conda_setup="$('$HOME/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        fi
        unset __conda_setup
    fi

    # Linuxbrew (if installed)
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# Load envman if available
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Source .env file if using Bitwarden secrets
if [ -f "$HOME/.dotfiles/.env" ]; then
    source "$HOME/.dotfiles/.env"
fi
