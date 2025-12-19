# macOS-specific Configuration

# macOS-specific exports
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

# Autojump
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# SSH agent with Keychain
if [ -f ~/.ssh/id_rsa ]; then
    nohup ssh-add --apple-use-keychain ~/.ssh/id_rsa > /dev/null 2>&1 & disown
fi

# Source global .env
[ -f "$HOME/.dotfiles/.env" ] && source "$HOME/.dotfiles/.env"

# Source macOS-specific .env
[ -f "$HOME/.dotfiles/.env.darwin" ] && source "$HOME/.dotfiles/.env.darwin"
