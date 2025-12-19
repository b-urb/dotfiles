# Linux-specific Configuration

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# SSH agent (standard Linux approach)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    if [ -f ~/.ssh/id_rsa ]; then
        ssh-add ~/.ssh/id_rsa 2>/dev/null
    fi
fi
