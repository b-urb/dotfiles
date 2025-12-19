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

# Load envman if available
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
