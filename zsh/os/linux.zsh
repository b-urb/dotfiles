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

# Autojump
[[ -s /etc/profile.d/autojump.zsh ]] && source /etc/profile.d/autojump.zsh

# SSH agent (standard Linux approach)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    if [ -f ~/.ssh/id_rsa ]; then
        ssh-add ~/.ssh/id_rsa 2>/dev/null
    fi
fi

# Source global .env
[ -f "$HOME/.dotfiles/.env" ] && source "$HOME/.dotfiles/.env"

# Source Linux-specific .env
[ -f "$HOME/.dotfiles/.env.linux" ] && source "$HOME/.dotfiles/.env.linux"
