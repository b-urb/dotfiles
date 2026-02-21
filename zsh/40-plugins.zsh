# Plugin Loading

zinit light junegunn/fzf
zinit light Aloxaf/fzf-tab
zinit for \
    zdharma-continuum/fast-syntax-highlighting

zinit load atuinsh/atuin

zinit from'gh-r' as'program' for \
    id-as'kubectx' bpick'kubectx*' ahmetb/kubectx \
    id-as'kubens' bpick'kubens*' ahmetb/kubectx

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

eval "$(zoxide init zsh)"

# Zellij control: enabled only when DOTFILES_ENABLE_ZELLIJ is truthy
case "${DOTFILES_ENABLE_ZELLIJ:l}" in
    1|true|yes|on)
        if command -v zellij >/dev/null 2>&1; then
            eval "$(zellij setup --generate-auto-start zsh)"
        fi
        ;;
esac
