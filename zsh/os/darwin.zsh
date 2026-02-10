# macOS-specific Configuration

# macOS-specific exports
export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:/opt/homebrew/opt/go@1.21/bin:$PATH"
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


# Bitwarden SSH agent (default on, opt-out with DOTFILES_DISABLE_BITWARDEN_SSH_AGENT=1)
__dotfiles_bw_ssh_sock=""
if [ -z "$DOTFILES_DISABLE_BITWARDEN_SSH_AGENT" ]; then
    if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
        for sock in \
            "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock" \
            "$HOME/.bitwarden-ssh-agent.sock"; do
            if [ -S "$sock" ]; then
                export SSH_AUTH_SOCK="$sock"
                __dotfiles_bw_ssh_sock="$sock"
                break
            fi
        done
    fi
fi

# SSH agent with Keychain
if [ -z "$__dotfiles_bw_ssh_sock" ] && [ -f ~/.ssh/id_rsa ]; then
    nohup ssh-add --apple-use-keychain ~/.ssh/id_rsa > /dev/null 2>&1 & disown
fi

# Source global .env
[ -f "$HOME/.dotfiles/.env" ] && source "$HOME/.dotfiles/.env"

# Source macOS-specific .env
[ -f "$HOME/.dotfiles/.env.darwin" ] && source "$HOME/.dotfiles/.env.darwin"
