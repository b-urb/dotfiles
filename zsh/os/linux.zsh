# Linux-specific Configuration

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

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


# Bitwarden SSH agent (default on, opt-out with DOTFILES_DISABLE_BITWARDEN_SSH_AGENT=1)
__dotfiles_bw_ssh_sock=""
if [ -z "$DOTFILES_DISABLE_BITWARDEN_SSH_AGENT" ]; then
    if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
        for sock in \
            "$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock" \
            "$HOME/.bitwarden-ssh-agent.sock" \
            "$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock"; do
            if [ -S "$sock" ]; then
                export SSH_AUTH_SOCK="$sock"
                __dotfiles_bw_ssh_sock="$sock"
                break
            fi
        done
    fi
fi

# SSH agent fallback (standard Linux approach)
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    if [ -f ~/.ssh/id_rsa ]; then
        ssh-add ~/.ssh/id_rsa 2>/dev/null
    fi
fi

# Source global .env
[ -f "$HOME/.dotfiles/.env" ] && source "$HOME/.dotfiles/.env"

# Source Linux-specific .env
[ -f "$HOME/.dotfiles/.env.linux" ] && source "$HOME/.dotfiles/.env.linux"
