# Aliases

# General
alias kb="kubectl"
alias res="source ~/.zshrc"
alias ls="eza"
alias htop="bpytop"
alias ping="gping"
alias du="dua"
alias dig="dog"
alias cat="bat"
alias python="python3"
alias vim="nvim"
alias j="z"

# Kubernetes
source ~/kubectl_aliases
alias kctx=kubectx
alias kns=kubens

# Git (if thefuck is available)
if command -v thefuck &> /dev/null; then
    eval $(thefuck --alias)
fi
