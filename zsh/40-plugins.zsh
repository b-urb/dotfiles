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

# Zellij control: set DOTFILES_ENABLE_ZELLIJ=0 to disable auto-start
if [[ "${DOTFILES_ENABLE_ZELLIJ}" != "0" ]] && command -v zellij >/dev/null 2>&1; then
    eval "$(zellij setup --generate-auto-start zsh)"
fi
