# Command Completions

# Load completions only if commands exist
if command -v kubectl &> /dev/null; then
    source <(kubectl completion zsh)
fi

if command -v golangci-lint &> /dev/null; then
    source <(golangci-lint completion zsh)
fi

if command -v kubebuilder &> /dev/null; then
    source <(kubebuilder completion zsh)
fi

if command -v spt &> /dev/null; then
    source <(spt --completions zsh)
fi
